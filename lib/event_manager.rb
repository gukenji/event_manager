require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone(phone)
  phone = phone.gsub(/[ ()-.]/,'').to_s
  if phone.length < 10 || phone.length > 11 || (phone.length == 11 && phone[0] != "1")
    "Bad number!"
  elsif phone.length == 11 && phone[0] == "1"
    phone[1..10]
  else
    phone
  end
end

def transform_to_hour(date)
  Time.strptime(date,"%m/%d/%y %k:%M").strftime("%k")
end

def transform_to_day_of_week(date)
  date = Time.strptime(date,"%m/%d/%y %k:%M").strftime("%d/%m/%Y")
  day = date[0..1].to_i
  month = date[3..4].to_i
  year = date[6..9].to_i
  day_of_week = Date.new(year,month,day).wday
end

def max_value(array)
  counter = Hash.new(0)
  array.each do |value|
    counter[value]+=1
  end
  counter.max_by{|key,value|value}[0]
end

filename = 'event_attendees.csv'
rows = CSV.read(filename).length



puts 'EventManager initialized.'
contents = CSV.open(
  filename,
  headers: true,
  header_converters: :symbol
)



template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = []
days = []
days_of_week = {0 => "Sunday", 1 => "Monday", 2 => "Tuesday", 3 => "Wednesday", 4 => "Thursday", 5 => "Friday", 6 => "Saturday"}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)  
  phone = clean_phone(row[:homephone])
  hours << transform_to_hour(row[:regdate])
  days << transform_to_day_of_week(row[:regdate])
  rows -=1
  puts "Please, wait more #{rows} times."


end
puts "Peak time: #{max_value(hours)}:00"
puts "Peak date: #{days_of_week[max_value(days)]}"
