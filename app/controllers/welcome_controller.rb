class WelcomeController < ApplicationController
  def index
    @timetables = Timetables.get_bus_now(Time.zone.now.strftime("%H"))
  end
end
