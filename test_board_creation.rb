require_relative 'config/environment'

Current.account = Account.first
Current.account_user = Current.account.account_users.first
Current.user = Current.account_user.user

puts "Account: #{Current.account.id}, User: #{Current.user.id}"

begin
  board = Current.account.kanban_boards.new(name: "Test Board", description: "Empty")
  board.save!
  
  puts "Board created successfully: #{board.id}"
  
  # Render the view to catch jbuilder errors
  view = ActionView::Base.with_empty_template_cache
  puts view.inspect
rescue => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts e.backtrace.take(20).join("\n")
end
