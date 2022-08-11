require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)
  RSpec.describe API do
    include Rack::Test::Methods
    def app
      API.new(ledger: ledger)
    end

    def post_data
      post '/expenses', JSON.generate(expense)
      parsed = JSON.parse(last_response.body)
    end

    def get_data
      get '/expenses', JSON.generate(expense)
      parsed = JSON.parse(last_response.body)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }
    let(:expense) { { 'some' => 'data' } }

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
          allow(ledger).to receive(:record)
            .with(:date)
            .and_return(RecordResult.new([{ 'payee' => 'Starbucks', 'amount' => 5.75,
                                            'date' => '2017-06-10' }]))
        end
        it 'returns the expense records as JSON' do
          get '/expenses/2017-06-10'
          expect(last_response.body).to include [{ 'payee' => 'Starbucks', 'amount' => 5.75,
                                                   'date' => '2017-06-10' }].to_json
        end

        it 'responds with a 200 (OK)' do
          get '/expenses/2017-06-10', JSON.generate(expense)
          expect(last_response.status).to eq 200
        end
      end

      context 'when there are no expenses on the given date' do
        before do
          allow(ledger).to receive(:record)
            .with(:date)
            .and_return(RecordResult.new([]))
        end
        it 'returns an empty array as JSON' do
          get '/expenses/', JSON.generate([])
          expect(last_response.body).to include [].to_json
        end
        it 'responds with a 200 (OK)' do
          expect(last_response.status).to eq 200
        end
      end
    end
  end
end
