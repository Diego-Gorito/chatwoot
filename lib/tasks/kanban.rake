# frozen_string_literal: true

namespace :kanban do
  desc 'Enable Kanban feature for all accounts'
  task enable_for_all: :environment do
    puts 'Enabling Kanban feature for all accounts...'

    total = Account.count
    enabled = 0
    already_enabled = 0

    Account.find_each do |account|
      if account.feature_enabled?('kanban')
        already_enabled += 1
        next
      end

      account.enable_features!('kanban')
      enabled += 1
      print '.'
    end

    puts "\n\n✅ Done!"
    puts "Total accounts: #{total}"
    puts "Already enabled: #{already_enabled}"
    puts "Newly enabled: #{enabled}"
  end

  desc 'Check Kanban feature status for all accounts'
  task status: :environment do
    total = Account.count
    enabled = Account.where('feature_flags & ? != 0', Featurable.feature_flag_value('kanban')).count
    disabled = total - enabled

    puts "\n📊 Kanban Feature Status:"
    puts "─" * 40
    puts "Total accounts: #{total}"
    puts "Kanban enabled: #{enabled} (#{(enabled.to_f / total * 100).round(2)}%)"
    puts "Kanban disabled: #{disabled} (#{(disabled.to_f / total * 100).round(2)}%)"
    puts "─" * 40
  end

  desc 'Enable Kanban for a specific account'
  task :enable, [:account_id] => :environment do |_t, args|
    unless args[:account_id]
      puts '❌ Error: Please provide an account_id'
      puts 'Usage: bundle exec rake kanban:enable[ACCOUNT_ID]'
      exit 1
    end

    account = Account.find_by(id: args[:account_id])
    unless account
      puts "❌ Error: Account with ID #{args[:account_id]} not found"
      exit 1
    end

    if account.feature_enabled?('kanban')
      puts "✅ Kanban is already enabled for account ##{account.id} (#{account.name})"
    else
      account.enable_features!('kanban')
      puts "✅ Kanban enabled for account ##{account.id} (#{account.name})"
    end
  end
end
