Fabricator(:tweet) do
  body { Faker::Lorem.paragraph(3) }
end
