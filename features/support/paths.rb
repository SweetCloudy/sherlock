module NavigationHelpers
  def path_to(page_name)
    case page_name    
    when /the\s+homepage/
      root_path
    when /the sign-in page/
      new_user_session_path
    when /the new case page/
      new_case_path
    when /details page of "Case #1"/
      case_path(Case.find_by_title('Case #1'))
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
      "Now, go and add a mapping in features/support/paths.rb"
    end
  end
end

World(NavigationHelpers)
