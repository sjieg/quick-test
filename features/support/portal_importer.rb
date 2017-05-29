#
# Custom cucumber formatter that extends the default 'pretty' formatter, and
# adds importing into a database.
#
# Author(s): Jens Finkhaeuser <jens@spritecloud.com>
#
# Copyright (c) 2010-2015 spriteCloud B.V. All rights reserved.
#
require 'cucumber/formatter/io'
require 'cucumber/formatter/pretty'

module SpriteCloud
  module Legacy
    #
    # NOTE:
    #   - Ignores language. We don't really need this, as what we save in the DB
    #     is exactly what's in the files.
    #
    class PortalImporter
      include Cucumber::Formatter::Io

      def timestamp(time)
        return (time.to_i * 1e6) + time.tv_usec
      end


      def initialize(step_mother, path_or_io, options)
        #Cucumber version >=2 contains only one parameter for ensure_io(). First check which cucumber version we are using
        #Cucumber::Formatter::Io.method(:ensure_io).arity Can be used to check the amount of parameters.
        begin
          @io = ensure_io(path_or_io, "portal_importer")
        rescue
          @io = ensure_io(path_or_io)
        end
      end


      def before_features(features)
        @tags = []
        now = Time.now.getutc
        @results = {
          "profile_id" => '@@SC_PROFILE_ID@@',
          "run_id" => '@@SC_RUN_ID@@',
          "executed" => now,
          "executed_timestamp" => timestamp(now),

          "os" => '@@SC_OS@@',
          "browser" => '@@SC_BROWSER@@',

          "features" => 0,

          "scenarios" => 0,
          "scenarios_passed" => 0,
          "scenarios_skipped" => 0,
          "scenarios_pending" => 0,
          "scenarios_undefined" => 0,
          "scenarios_failed" => 0,

          "steps" => 0,
          "steps_passed" => 0,
          "steps_skipped" => 0,
          "steps_pending" => 0,
          "steps_undefined" => 0,
          "steps_failed" => 0,

          "feature_results_attributes" => [],
        }
      end



      def after_features(features)
        # Update results
        @results["execution_time"] = Time.now.getutc - @results["executed"]

        require 'json'
        @io.puts @results.to_json
        @io.flush
      end



      def before_tags(tags)
        if tags.respond_to?(:tags)
          tags = tags.tags
        end
        tags.each do |tag|
          @tags << force_charset(tag.name)
        end
      end



      def before_feature(feature)
        split = force_charset(feature.name).split("\n", 2)
        @cur_feature = {
          "name" => split[0],
          "user_story" => split[1],
          "file" => force_charset(feature.file),

          "scenarios" => 0,
          "scenarios_passed" => 0,
          "scenarios_skipped" => 0,
          "scenarios_pending" => 0,
          "scenarios_undefined" => 0,
          "scenarios_failed" => 0,

          "steps" => 0,
          "steps_passed" => 0,
          "steps_skipped" => 0,
          "steps_pending" => 0,
          "steps_undefined" => 0,
          "steps_failed" => 0,

          "steplist_results_attributes" => [],
        }
      end



      def after_feature(feature)
        # Callbacks for tags are inconsistent; before_tags is called after
        # before_feature (makes sense, as before_feature is called before a
        # feature file gets processed), which means the only way we can get at
        # the feature tags is here in after_feature.
        @cur_feature["tags"] = @tags[0]
        @tags = []

        # Determine feature status
        if @cur_feature["scenarios_failed"] > 0 then
          @cur_feature["status"] = :failed
        elsif @cur_feature["scenarios_undefined"] > 0 then
          @cur_feature["status"] = :undefined
        elsif @cur_feature["scenarios_pending"] > 0 then
          @cur_feature["status"] = :pending
        elsif @cur_feature["scenarios_passed"] > 0 then
          @cur_feature["status"] = :passed
        elsif @cur_feature["scenarios_skipped"] > 0 then
          @cur_feature["status"] = :skipped
        else
          raise "Empty feature?"
        end

        @results["feature_results_attributes"] << @cur_feature
        @results["features"] += 1

        @results["scenarios"] += @cur_feature["scenarios"]
        @results["scenarios_passed"] += @cur_feature["scenarios_passed"]
        @results["scenarios_skipped"] += @cur_feature["scenarios_skipped"]
        @results["scenarios_pending"] += @cur_feature["scenarios_pending"]
        @results["scenarios_undefined"] += @cur_feature["scenarios_undefined"]
        @results["scenarios_failed"] += @cur_feature["scenarios_failed"]

        @results["steps"] += @cur_feature["steps"]
        @results["steps_passed"] += @cur_feature["steps_passed"]
        @results["steps_skipped"] += @cur_feature["steps_skipped"]
        @results["steps_pending"] += @cur_feature["steps_pending"]
        @results["steps_undefined"] += @cur_feature["steps_undefined"]
        @results["steps_failed"] += @cur_feature["steps_failed"]

        @cur_feature = nil
      end



      def after_background(background)
        # Only for backgrounds
        finalize_steplist
        @cur_feature["steplist_results_attributes"] << @cur_steplist
      end



      def after_feature_element(feature_element)
        # Only for top-level scenarios and scenario outlines
        finalize_steplist

        to_merge = nil
        if not @cur_outline.nil? then
          to_merge = @cur_outline

          # Determine feature status
          if @cur_outline["scenarios_failed"] > 0 then
            @cur_outline["status"] = :failed
          elsif @cur_outline["scenarios_undefined"] > 0 then
            @cur_outline["status"] = :undefined
          elsif @cur_outline["scenarios_pending"] > 0 then
            @cur_outline["status"] = :pending
          elsif @cur_outline["scenarios_passed"] > 0 then
            @cur_outline["status"] = :passed
          elsif @cur_outline["scenarios_skipped"] > 0 then
            @cur_outline["status"] = :skipped
          else
            raise "Empty scenario outline?"
          end

          # By resetting @cur_outline, we're signalling that the next steplist is
          # a top-level steplist again.
          @cur_outline = nil
        elsif not @cur_steplist.nil? then
          to_merge = @cur_steplist

          # As to_merge doesn't have scenario stats, we need to manually adjust
          # @cur_feature's stats now. The order of these tests is important.
          @cur_feature["scenarios"] += 1
          if @cur_steplist["status"] == :failed then
            @cur_feature["scenarios_failed"] += 1
          elsif @cur_steplist["status"] == :undefined then
            @cur_feature["scenarios_undefined"] += 1
          elsif @cur_steplist["status"] == :pending then
            @cur_feature["scenarios_pending"] += 1
          elsif @cur_steplist["status"] == :passed then
            @cur_feature["scenarios_passed"] += 1
          elsif @cur_steplist["status"] == :skipped then
            @cur_feature["scenarios_skipped"] += 1
          else
            raise "Unknown status '#{@cur_steplist["status"]}', #{@cur_steplist["inspect"]}"
          end
        end

        @cur_feature["steplist_results_attributes"] << to_merge

        # Merge scenario stats
        @cur_feature["scenarios"] += to_merge["scenarios"]
        @cur_feature["scenarios_passed"] += to_merge["scenarios_passed"]
        @cur_feature["scenarios_skipped"] += to_merge["scenarios_skipped"]
        @cur_feature["scenarios_pending"] += to_merge["scenarios_pending"]
        @cur_feature["scenarios_undefined"] += to_merge["scenarios_undefined"]
        @cur_feature["scenarios_failed"] += to_merge["scenarios_failed"]

        # Merge step stats
        @cur_feature["steps"] += to_merge["steps"]
        @cur_feature["steps_passed"] += to_merge["steps_passed"]
        @cur_feature["steps_skipped"] += to_merge["steps_skipped"]
        @cur_feature["steps_pending"] += to_merge["steps_pending"]
        @cur_feature["steps_undefined"] += to_merge["steps_undefined"]
        @cur_feature["steps_failed"] += to_merge["steps_failed"]

        # Make sure tags don't accumulate over feature elements
        @tags = [@tags[0].nil? ? [] : @tags[0]]
      end



      def scenario_name(keyword, name, file_colon_line, source_indent)
        steplist(:scenario, name, file_colon_line)
      end



      def background_name(keyword, name, file_colon_line, source_indent)
        steplist(:background, name, file_colon_line)
      end


      # This still takes an argument but does no longer use it. Turned it into optional parameter
      def before_examples_array(*array)
        # This means that @cur_steplist must be a scenario outline.
        @cur_steplist["steplist_type"] = :scenario_outline
        @cur_outline = @cur_steplist
        # We don't want to count an outline step definitions, just those for each
        # step.
        @cur_outline["steps"] = @cur_outline["steps_failed"] = @cur_outline["steps_undefined"] = @cur_outline["steps_passed"] = @cur_outline["steps_skipped"] = @cur_outline["steps_pending"] = 0
      end


      # This still takes an argument but does no longer use it. Turned it into optional parameter
      def after_examples_array(*array)
        merge_into_outline
      end


      def before_step(step)
        now = Time.now.getutc
        @cur_step = {
          "index" => @cur_steplist["step_results_attributes"].size,
          "executed" => now,
          "executed_timestamp" => timestamp(now),
        }
      end


      def before_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line)
        step_result = {
          "index" => @cur_steplist["step_results_attributes"].size,
          "file_colon_line" => file_colon_line,
          "status" => status,
        }
        step_result.merge! @cur_step

        begin
          step_result["summary"] = "#{force_charset(keyword)} #{force_charset(step_match.format_args)}"
        rescue ArgumentError
          step_result["summary"] = "#{force_charset(keyword)} #{force_charset(step_match.name)}"
        end

        if not exception.nil? then
          step_result["exception_class"] = force_charset(exception.class.name)
          step_result["exception_message"] = force_charset(exception.message)
          step_result["exception_backtrace"] = force_charset(exception.backtrace.join("\n"))
        end

        if not multiline_arg.nil? then
          if ["Cucumber::Ast::PyString", "Cucumber::Ast::DocString"].include?(multiline_arg.class.name) then
            step_result["multiline_args"] = { :py_string => force_charset(multiline_arg.to_step_definition_arg) }
          elsif "Cucumber::Ast::Table" == multiline_arg.class.name then
            table = []
            multiline_arg.cell_matrix.each do |row|
              ra = []
              row.each do |cell|
                ra << force_charset(cell.value)
              end
              table << ra
            end
            step_result["multiline_args"] = { :table => table }
          elsif "Cucumber::Core::Ast::DataTable" == multiline_arg.class.name then
            step_result["multiline_args"] = { :table => multiline_arg.raw }
          else
            raise "Unknown type of multiline argument"
          end
        end

        @cur_steplist["steps"] += 1
        if :failed == step_result["status"] then
          @cur_steplist["steps_failed"] += 1
        elsif :undefined == step_result["status"] then
          @cur_steplist["steps_undefined"] += 1
        elsif :passed == step_result["status"] then
          @cur_steplist["steps_passed"] += 1
        elsif :skipped == step_result["status"] then
          @cur_steplist["steps_skipped"] += 1
        elsif :pending == step_result["status"] then
          @cur_steplist["steps_pending"] += 1
        else
          raise "Unknown step status: #{step_result["status"]}"
        end

        @cur_steplist["step_results_attributes"] << step_result
      end

      private

      def finalize_steplist
        return if @cur_steplist.nil?

        if @cur_steplist["steps"] > 0 then
          # The order of these tests is important, as earlier tests overrule
          # later tests, i.e. a StepList with some failed and some undefined steps
          # will be counted as failed.
          if @cur_steplist["steps_failed"] > 0 then
            @cur_steplist["status"] = :failed
          elsif @cur_steplist["steps_undefined"] > 0 then
            @cur_steplist["status"] = :undefined
          elsif @cur_steplist["steps_pending"] > 0 then
            @cur_steplist["status"] = :pending
          elsif @cur_steplist["steps_passed"] > 0 then
            @cur_steplist["status"] = :passed
          elsif @cur_steplist["steps_skipped"] > 0 then
            @cur_steplist["status"] = :skipped
          else
            raise "Empty test?"
          end
        else
          # No steps => pending
          @cur_steplist["status"] = :pending
        end
      end



      def merge_into_outline
        return if @cur_outline.nil?
        return if @cur_steplist.nil?

        return if @cur_outline == @cur_steplist

        finalize_steplist

        @cur_outline["children_attributes"] << @cur_steplist

        @cur_outline["steps"] += @cur_steplist["steps"]
        @cur_outline["steps_undefined"] += @cur_steplist["steps_undefined"]
        @cur_outline["steps_skipped"] += @cur_steplist["steps_skipped"]
        @cur_outline["steps_passed"] += @cur_steplist["steps_passed"]
        @cur_outline["steps_failed"] += @cur_steplist["steps_failed"]

        # The order of these tests is important
        @cur_outline["scenarios"] += 1
        if @cur_steplist["status"] == :failed then
          @cur_outline["scenarios_failed"] += 1
        elsif @cur_steplist["status"] == :undefined then
          @cur_outline["scenarios_undefined"] += 1
        elsif @cur_steplist["status"] == :pending then
          @cur_outline["scenarios_pending"] += 1
        elsif @cur_steplist["status"] == :passed then
          @cur_outline["scenarios_passed"] += 1
        elsif @cur_steplist["status"] == :skipped then
          @cur_outline["scenarios_skipped"] += 1
        else
          raise "Unknown status '#{@cur_steplist["status"]}', #{@cur_steplist["inspect"]}"
        end
      end


      def steplist(type, name, file_colon_line)
        merge_into_outline

        @cur_steplist = {
          "name" => force_charset(name),
          "file_colon_line" => force_charset(file_colon_line),
          "steplist_type" => type,
          "tags" => @tags,

          "scenarios" => 0,
          "scenarios_passed" => 0,
          "scenarios_skipped" => 0,
          "scenarios_pending" => 0,
          "scenarios_undefined" => 0,
          "scenarios_failed" => 0,

          "steps" => 0,
          "steps_passed" => 0,
          "steps_skipped" => 0,
          "steps_pending" => 0,
          "steps_undefined" => 0,
          "steps_failed" => 0,

          "children_attributes" => [],
          "step_results_attributes" => [],
        }
      end


      def force_charset(str)
        if Encoding::ASCII_8BIT == str.encoding
          begin
            str = str.encode!(Encoding::ISO_8859_1)
          rescue EncodingError
            str = str.encode!(Encoding::ISO_8859_1, :invalid => :replace, :undef => :replace)
          end
        end
        return str
      end

    end # class PortalImporter

  end # module Legacy
end # module SpriteCloud
