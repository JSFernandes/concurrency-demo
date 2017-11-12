class Checkout
  include ForkBreak::Breakpoints

  def initialize(user_id:, event_id:)
    @user = User.find(user_id)
    @event = Event.find(event_id)
  end

  def process
    breakpoints << :before_transaction
    user.with_lock do
      fetch_ticket
      breakpoints << :after_fetch
      update_user_balance
      breakpoints << :after_balance_update
      assign_ticket_to_user
      breakpoints << :after_ticket_update
    end
  end

  private

  attr_reader :event
  attr_accessor :user, :ticket

  def fetch_ticket
    self.ticket = Ticket.where(user_id: nil, event_id: event.id).sample
    raise "There are no available tickets for this event :(" unless ticket
  end

  def update_user_balance
    new_user_balance = user.balance_in_cents - event.price_in_cents
    raise "User does not have enough balance for this event :(" if new_user_balance.negative?
    user.update_attributes!(balance_in_cents: new_user_balance)
  end

  def assign_ticket_to_user
    ticket.update_attributes!(user_id: user.id)
  end
end
