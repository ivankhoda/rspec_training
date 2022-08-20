require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)

  RSpec.describe API do
    let(:expense) do
      {
        'payee' => 'Starbucks', 'amount' => 5.75,
        'date' => '2017-06-10', 'id' => '10'
      }
    end
    include Rack::Test::Methods
    def app
      API.new(ledger: ledger)
    end

    def post_data
      post '/expenses', JSON.generate(expense)
      parsed = JSON.parse(last_response.body)
    end

    def parse_data
      JSON.generate(expense)
      parsed = JSON.parse(last_response.body)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    describe 'POST /expenses' do
      context 'when the expense is successfully recorded' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(true, 417, nil))
        end
        # ... specs go here ...
        it 'returns the expense id' do
          expect(post_data).to include('expense_id' => 417)
        end

        it 'responds with a 200 (OK)' do
          post_data

          expect(last_response.status).to eq(200)
        end
      end
      context 'when the expense fails validation' do
        # ... specs go here ...
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          expect(post_data).to include('error' => 'Expense incomplete')
        end
        it 'responds with a 422 (Unprocessable entity)' do
          post_data
          expect(last_response.status).to eq(422)
        end
      end
    end
    describe 'GET /expenses/:date' do
      context 'when expenses exist on the given date' do
        before do
          allow(ledger).to receive(:expenses_on)
            .with('2017-06-10')
            .and_return(RecordResult.new([]))
        end
        it 'returns the expense records as JSON' do
          get '/expenses/2017-06-10', JSON.generate([expense])
          expect(last_response.body).to include [].to_json
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-10'
          expect(last_response.status).to eq 200
        end
      end

      context 'when there are no expenses on the given date' do
        before do
          allow(ledger).to receive(:record)
            .and_return(RecordResult.new([]))
        end
        it 'returns an empty array as JSON' do
          get '/expenses', JSON.generate([])
          expect(last_response.body).to include [].to_json
        end
        it 'responds with a 200 (OK)' do
          get '/expenses'
          expect(last_response.status).to eq 200
        end
      end
    end
    describe 'GET /expense/:id' do
      context 'when expense with id exists' do
        before do
          allow(ledger).to receive(:get_expense)
            .with(
              '10'
            )
            .and_return(expense)
        end
        it 'returns the expense record as json' do
          get '/expense/10'
          expect(parse_data).to include('id' => '10')
        end
        it 'responds with a 200 (OK)' do
          get '/expense/10'
          expect(last_response.status).to eq 200
        end
      end
      context 'when expense with id does not exist' do
        before do
          allow(ledger).to receive(:get_expense)
            .with('11a')
            .and_return([])
        end
        it 'returns an empty array' do
          get '/expense/11a'
          expect(last_response.body).to eq([].to_json)
        end
        it 'respond with 200' do
          get '/expense/11a'
          expect(last_response.status).to eq 200
        end
      end
    end
    describe 'PATCH /expense/:id' do
      context 'patch expense with correct id' do
        before do
          allow(ledger).to receive(:get_expense)
            .with(
              '10'
            )
            .and_return(expense)
          allow(ledger).to receive(:patch_expense)
            .with('10', { amount: 5.00.to_f, payee: 'Lolbucks', date: '2022-08-17' })
            .and_return(expense.merge!({ 'amount' => 5.00.to_f, 'payee' => 'Lolbucks', 'date' => '2022-08-17' }))
        end
        it 'patches expense with correct id' do
          expense_id = '10'
          put "/expense/#{expense_id}", expense: { amount: 5.0.to_f, payee: 'Lolbucks', date: '2022-08-17' }
          expect(last_response.status).to eq 200
          expect(last_response.body).to eql(expense.to_json)
        end
      end

      # end
      context 'patch expense with incorrect id' do
        before do
          allow(ledger).to receive(:get_expense)
            .with(
              '11f'
            )
            .and_return([])
          allow(ledger).to receive(:patch_expense)
            .with('11f', { amount: 5.00.to_f, payee: 'Lolbucks', date: '2022-08-17' })
            .and_return([])
        end
        it 'return a 404 error when expense id is incorrect' do
          expense_id = '11f'
          put "/expense/#{expense_id}", expense: { amount: 5.0.to_f, payee: 'Lolbucks', date: '2022-08-17' }
          expect(last_response.status).to eq 404
        end
      end
    end
  end
end
