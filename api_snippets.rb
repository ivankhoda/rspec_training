class API < Sinatra::Base
  def initialize
    @ledger = Ledger.new
    super() # rest of initialization from Sinatra
  end
end
# Later, callers do this:
app = API.new(ledger: Ledger.new)
