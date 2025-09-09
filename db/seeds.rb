puts "Seeding courses..."

courses = [
  {
    name: "Bachelor of Computer Science",
    provider: "University Program",
    category: :technology,
    hours: 3600,
    description: "Full undergraduate CS program covering algorithms, data structures, and systems."
  },
  {
    name: "Bachelor of Business Administration",
    provider: "University Program",
    category: :business,
    hours: 3200,
    description: "Undergraduate program focused on management, finance, and operations."
  },
  {
    name: "Technical English for Developers",
    provider: "Internal Academy",
    category: :language,
    hours: 40,
    description: "English for documentation reading and technical communication in software projects."
  },
  {
    name: "Spanish for Business",
    provider: "Language Institute",
    category: :language,
    hours: 40,
    description: "Spanish vocabulary and practice tailored to corporate scenarios."
  },
  {
    name: "AWS Certified Solutions Architect",
    provider: "AWS Training",
    category: :technology,
    hours: 50,
    description: "Preparation for the AWS Solutions Architect Associate certification."
  },
  {
    name: "Scrum Master Certification",
    provider: "Scrum Alliance",
    category: :business,
    hours: 24,
    description: "Agile concepts and Scrum practices to prepare for Scrum Master certification."
  },
  {
    name: "Advanced Ruby on Rails",
    provider: "Udemy",
    category: :technology,
    hours: 30,
    description: "Intensive course on building production-ready applications with Ruby on Rails."
  },
  {
    name: "Figma Essentials",
    provider: "DesignLab",
    category: :design,
    hours: 20,
    description: "Foundations of product design and interface prototyping with Figma."
  },
  {
    name: "SQL for Data Analytics",
    provider: "Coursera",
    category: :data,
    hours: 25,
    description: "Querying relational databases and building analytics-ready data sets."
  },
  {
    name: "Data Visualization Fundamentals",
    provider: "Coursera",
    category: :data,
    hours: 18,
    description: "Principles and practices for effective data visualization."
  }
]

# Idempotent upsert by natural key (name + provider)
courses.each do |attrs|
  record = Course.find_or_initialize_by(name: attrs[:name], provider: attrs[:provider])
  record.assign_attributes(attrs)
  record.save!
end

puts "Courses seeded: #{Course.count}"
