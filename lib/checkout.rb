class Checkout
  def initialize(user_id:, event_id:)
    @user = User.find(user_id)
    @event = Event.find(event_id)
  end

  def process
    ActiveRecord::Base.transaction do
      fetch_ticket
      update_user_balance
      assign_ticket_to_user
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
