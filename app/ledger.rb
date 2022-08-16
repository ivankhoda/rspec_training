require_relative '../config/sequel'

module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message, :params)
  class Ledger
    def record(expense)
      unless expense.key?('payee')
        message = 'Invalid expense: `payee` is required'
        return RecordResult.new(false, nil, message)
      end
      DB[:expenses].insert(expense)
      id = DB[:expenses].max(:id)
      RecordResult.new(true, id, nil)
    end

    def expenses_on(date)
      DB[:expenses].where(date: date).all
    end

    def get_expense(id)
      DB[:expenses].where(id: id).all
    end

    def patch_expense(id, params)
      expense = DB[:expenses].where(id: id)
      if !expense.first.nil?
        expense.update(params)
      else
        message = "Invalid expense id: #{id} is not exists"
        RecordResult.new(false, nil, message)
      end
    end
  end
end
