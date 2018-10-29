def draw_from_path(route_path)
  scope route_path do
    draw("saas_api/#{route_path}")
  end
end

draw_from_path('v1')
draw_from_path('v2')
