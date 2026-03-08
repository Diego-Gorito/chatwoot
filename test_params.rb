require 'action_controller'
params = ActionController::Parameters.new({
  board: {
    name: "Test",
    steps_attributes: [
      { name: "Step 1", cancelled: false }
    ]
  }
})

permitted = params.require(:board).permit(
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
  puts "Map successful: #{permitted[:steps_attributes]}"
rescue => e
  puts "Error in map: #{e.class}: #{e.message}"
end

begin
  steps_attrs = params.dig(:board, :steps_attributes)
  steps_attrs.each_with_index do |step_attrs, index|
    if step_attrs.is_a?(Array)
      step_attrs = step_attrs.last
    end
    val = step_attrs[:cancelled]
    puts "Val: #{val}"
  end
rescue => e
  puts "Error in apply_cancelled: #{e.class}: #{e.message}"
end
