require_relative 'config/environment'

hash_params = ActionController::Parameters.new({
  board: {
    name: "Test",
    steps_attributes: {
      "0" => { name: "Step 1", cancelled: true }
    }
  }
})

permitted = hash_params.require(:board).permit(
  :name,
  :description,
  settings: {},
  steps_order: [],
  steps_attributes: [
    :name, :description, :color, :cancelled,
  ]
)

begin
  if permitted[:steps_attributes].present?
    permitted[:steps_attributes] = permitted[:steps_attributes].map do |step_attrs|
      step_attrs.except(:cancelled)
    end
  end
  puts "SUCCESS!"
rescue => e
  puts "VULNERABILITY CONFIRMED 1: #{e.class}: #{e.message}"
end

begin
  steps_attrs = hash_params.dig(:board, :steps_attributes)
  steps_attrs.each_with_index do |step_attrs, index|
    val = step_attrs[:cancelled]
  end
  puts "SUCCESS 2!"
rescue => e
  puts "VULNERABILITY CONFIRMED 2: #{e.class}: #{e.message}"
end

