Given(/^the user expects a result in a multi_find lookup$/) do
  elm = browser.multi_find(
      :selectors => [
          {:input => {:type => 'texta'}},
          {:like => [:a, :id, 'link-sc']}
      ]
  )
  unless elm.text == 'blog'
    error "Expected element with text `blog`, but received `#{elm.text}`"
  end
end

Given(/^the user expects an error in a multi_find lookup$/) do
  err = ''
  begin
    elm = browser.multi_find(
        :selectors => [
            {:input => {:type => 'texta'}},
            {:like => [:a, :id, 'link-sca']}
        ]
    )
    err = "Expected an error looking for elements with no results."
  rescue RuntimeError => e
    puts "Caught expected error: #{e.message}"
  end
  error err unless err.empty?
end

Given(/^the user expects no error in a multi_find lookup$/) do
  elm = browser.multi_find(
      :selectors => [
          {:input => {:type => 'texta'}},
          {:like => [:a, :id, 'link-sca']}
      ],
      :throw => false
  )
  unless elm.nil?
    error "Expected the result to be nil."
  end
end

Given(/^the user expects 2 results in a multi_find_all lookup$/) do
  elm = browser.multi_find_all(
      :selectors => [
          {:input => {:type => 'text'}},
          {:like => [:a, :id, 'link-sc']}
      ]
  )
  unless elm.length == 2
    error "Expected 2 elements, but received `#{elm.length}`"
  end
end

Given(/^the user expects 1 results in a multi_find_all lookup$/) do
  elm = browser.multi_find_all(
      :selectors => [
          {:input => {:type => 'texta'}},
          {:like => [:a, :id, 'link-sc']}
      ]
  )
  unless elm[0].text == 'blog'
    error "Expected element with text `blog`, but received `#{elm.text}`"
  end
end

Given(/^the user expects 4 existing results in a multi_find_all lookup$$/) do
  elm = browser.multi_find_all(
      :selectors => [
          {:input => {:type => 'text'}, :filter_by => :exists?},
          {:like => [:a, :id, 'link-sc']}
      ]
  )
  unless elm.length == 4
    error "Expected 4 elements, but received `#{elm.length}`"
  end
end

Given(/^the user expects an error in a multi_find_all lookup$/) do
  err = ''
  begin
    elm = browser.multi_find_all(
        :selectors => [
            {:input => {:type => 'texta'}},
            {:like => [:a, :id, 'link-sca']}
        ]
    )
    err = "Expected an error looking for elements with no results."
  rescue RuntimeError => e
    puts "Caught expected error: #{e.message}"
  end
  error err unless err.empty?
end

Given(/^the user expects no error in a multi_find_all lookup$/) do
  elm = browser.multi_find_all(
      :selectors => [
          {:input => {:type => 'texta'}},
          {:like => [:a, :id, 'link-sca']}
      ],
      :throw => false
  )
  unless elm.length == 0
    error "Expected to receive 0 results."
  end
end

Given(/^the user expects an error in a multi_find_all lookup matching all elements$/) do
  err = ''
  begin
    elm = browser.multi_find_all(
        :selectors => [
            {:input => {:type => 'texta'}},
            {:like => [:a, :id, 'link-sc']}
        ],
        :mode => :match_all
    )
    err = "Expected an error matching all elements with results."
  rescue RuntimeError => e
    puts "Caught expected error: #{e.message}"
  end
  error err unless err.empty?
end
Given(/^the user expects no error in a multi_find_all lookup matching all elements$/) do

  elm = browser.multi_find_all(
      :selectors => [
          {:input => {:type => 'texta'}},
          {:like => [:a, :id, 'link-sc']}
      ],
      :mode => :match_all,
      :throw => false
  )
  unless elm.length == 0
    error "Expected to receive 0 results."
  end
end