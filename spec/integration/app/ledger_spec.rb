require_relative '../../../app/ledger'
require_relative '../../../config/sequel'

module ExpenseTracker
  RSpec.describe Ledger, :aggregate_failures, :db do
    let(:ledger) { Ledger.new }
    let(:expense) do
      {
        'payee' => 'Starbucks', 'amount' => 5.75,
        'date' => '2017-06-10'
      }
    end
    describe '#record' do
      # ... contexts go here ...
      context 'with a valid expense' do
        it 'successfully saves the expense in the DB' do
          result = ledger.record(expense)
          expect(result).to be_success
          expect(DB[:expenses].all).to match [a_hash_including(
            id: result.expense_id,
            payee: 'Starbucks',
            amount: 5.75,
            date: Date.iso8601('2017-06-10')
          )]
        end
      end
      context 'when the expense lacks a payee' do
        it 'rejects the expense as invalid' do
          expense.delete('payee')
          result = ledger.record(expense)
          expect(result).not_to be_success
          expect(result.expense_id).to eq(nil)
          expect(result.error_message).to include('`payee` is required')
          expect(DB[:expenses].count).to eq(0)
        end
      end
    end
    describe '#expenses_on' do
      it 'returns all expenses for the provided date' do
        result_1 = ledger.record(expense.merge('date' => '2017-06-10'))
        result_2 = ledger.record(expense.merge('date' => '2017-06-10'))
        result_3 = ledger.record(expense.merge('date' => '2017-06-11'))
        expect(ledger.expenses_on('2017-06-10')).to contain_exactly(a_hash_including(id: result_1.expense_id),
                                                                    a_hash_including(id: result_2.expense_id))
      end
      it 'returns a blank array when there are no matching expenses' do
        expect(ledger.expenses_on('2017-06-10')).to eq([])
      end
    end
    describe 'get expense by id' do
      context 'with a valid id' do
        it 'returns an expense by given id' do
          result = ledger.record(expense.merge('date' => '2022-08-14'))
          expect(ledger.get_expense(10)).to contain_exactly(a_hash_including(id: result.expense_id))
        end
      end

      context 'with an invalid id' do
        it 'return message when invalid expense id was provided' do
          by_non_existing_id = 0o1
          expect(ledger.get_expense(by_non_existing_id).count).to eq(0)
        end
      end
    end
    describe 'patch expense' do
      context 'with a valid id' do
        it 'returns patched expense' do
          result = ledger.record(expense.merge('date' => '2022-08-16', 'amount' => '6'))
          ledger.patch_expense(result.expense_id, { 'amount' => 7.00, 'date' => '2022-08-16' })
          expect(DB[:expenses].all).to match [a_hash_including(
            id: result.expense_id,
            payee: 'Starbucks',
            amount: 7.00,
            date: Date.iso8601('2022-08-16')
          )]
        end
      end
      context 'returns error message if expense not found' do
        it 'returns error message' do
          non_existing_id = 0o1
          result = ledger.patch_expense(non_existing_id, { 'amount' => 7.00, 'date' => '2022-08-16' })
          expect(result.error_message).to include("Invalid expense id: #{non_existing_id} is not exists")
          expect(DB[:expenses].count).to eq(0)
        end
      end
      context 'with empty body' do
        it 'refuse to patch if body is empty' do
          exp = ledger.record(expense.merge('date' => '2022-08-16', 'amount' => '6'))
          result = ledger.patch_expense(exp.expense_id, { 'amount' => '', 'date' => '' })

          expect(result.error_message).to include('Invalid params: some params are empty')
        end
      end
    end
  end
end
