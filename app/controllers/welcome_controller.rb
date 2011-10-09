class WelcomeController < ApplicationController
  def index
    @timetables = Timetables.get_bus_now(Time.now.strftime("%H"))
  end
end
