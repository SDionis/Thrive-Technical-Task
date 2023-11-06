require 'json'

begin
  companies_data = JSON.parse(File.read('companies.json'))
  users_data = JSON.parse(File.read('users.json'))
rescue Errno::ENOENT => e
  puts "Error: #{e.message}. Please make sure the input files exist."
  exit
rescue JSON::ParserError => e
  puts "Error: Invalid JSON format in input files. #{e.message}"
  exit
end

# Open output.txt file to store the results with error handling
begin
  output_file = File.open('output.txt', 'w')
rescue Errno::EACCES => e
  puts "Error: #{e.message}. Permission denied to create the output file."
  exit
end

# Iterate through each company, sorted by company ID
companies_data.sort_by { |company| company['id'] }.each do |company|
  company_id = company['id']
  company_name = company['name']
  company_top_up = company['top_up']
  company_email_status = company['email_status']

  # Initialize variables to track total top-up for the current company
  total_top_up = 0

  # Arrays to store emailed and not emailed users
  users_emailed = []
  users_not_emailed = []

  # Iterate through users, sorted by last name and first name
  users_data.sort_by { |user| [user['last_name'], user['first_name']] }.each do |user|
    # Check if the user belongs to the current company and is active
    if user['company_id'] == company_id && user['active_status']
      user_tokens = user['tokens']
      user_email = user['email']
      user_last_name = user['last_name']
      user_first_name = user['first_name']

      # Determine whether the user should be emailed based on company and user email status
      if company_email_status && user['email_status']
        users_emailed << "#{user_last_name}, #{user_first_name}, #{user_email}"
      else
        users_not_emailed << "#{user_last_name}, #{user_first_name}, #{user_email}"
      end

      # Calculate new token balance for the user after top-up
      new_tokens = user_tokens + company_top_up
      total_top_up += company_top_up

      # Store user information in the output file
      output_file.puts("\t#{user_last_name}, #{user_first_name}, #{user_email}")
      output_file.puts("\t  Previous Token Balance: #{user_tokens}")
      output_file.puts("\t  New Token Balance: #{new_tokens}")
    end
  end

  # Output results for the current company to the output file
  output_file.puts("Company Id: #{company_id}")
  output_file.puts("Company Name: #{company_name}")
  output_file.puts("Users Emailed:")
  output_file.puts(users_emailed.map { |user| "\t#{user}" }.join("\n"))
  output_file.puts("Users Not Emailed:")
  output_file.puts(users_not_emailed.map { |user| "\t#{user}" }.join("\n"))
  output_file.puts("\tTotal amount of top-ups for #{company_name}: #{total_top_up}\n\n")
end

# Close the output file after writing the results
output_file.close

puts "Processing completed. Results saved in output.txt."
