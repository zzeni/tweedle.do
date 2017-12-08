Fabricator(:user) do
  name { Faker::LordOfTheRings.unique.character }
  email { Faker::Internet.unique.email }
  password "123456"
end
