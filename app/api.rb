require 'sinatra/base'
require 'json'
require_relative 'ledger'

module ExpenseTracker
  class API < Sinatra::Base
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end
    post '/expenses' do
      # JSON.generate('expense_id' => 42)
      expense = JSON.parse(request.body.read)
      result = @ledger.record(expense)

      if result.success?
        JSON.generate('expense_id' => result.expense_id)
      else
        status 422
        JSON.generate('error' => result.error_message)
      end
    end
    get '/expenses/:date' do
      if params[:date].nil?
        JSON.generate([])

      else
        date = params[:date]
        result = [{ 'payee' => 'Starbucks', 'amount' => 5.75,
                    'date' => date }]
        JSON.generate(result)

      end
    end
  end
end
