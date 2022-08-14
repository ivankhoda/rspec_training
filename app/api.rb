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
      date = params[:date]
      result = @ledger.expenses_on(date)
      JSON.generate(result)
    end

    get '/expense/:id' do
      id = params[:id]
      expense = @ledger.get_expense(id)
      JSON.generate(expense)
    end

    get '/expenses' do
      status 200
      JSON.generate([])
    end
  end
end
