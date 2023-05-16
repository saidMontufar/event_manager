require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "time"

# Zip code to string > Prepends 0s until length = 5 > Slices if length is larger than 5
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone(phone)
  if phone.length == 10
    phone
  elsif phone.length == 11 && phone[0] == "1"
    phone = phone[1..10]
  else
    phone = "0000000000"
  end
end

def clean_date(regdate)
  Time.strptime(regdate, "%Y/%d/%m %H:%M")
end

#Retreives legistlators names by Zipcode,Country, Role
def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  #Exeption Classs to handle errors wit "begin" and "rescue"
  begin
    legislators =
      civic_info.representative_info_by_address(
        address: zip,
        levels: "country",
        roles: %w[legislatorUpperBody legislatorLowerBody]
      ).officials
    legislators = legislators.officials
    legislators_names = legislators.map(&:name)
    legislators_strings = legislators_names.join(", ")
  rescue StandardError
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thankyou_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")
  filename = "output/thanks_#{id}.html"
  File.open(filename, "w") { |file| file.puts form_letter }
end

def key_count(k, ary)
  ary.has_key?(k) ? ary[k] += 1 : ary[k] = 1
end
puts "EventManager initialized."

contents =
  CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter
peeak_time = {}
peak_day = {}
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  date = clean_date(row[:regdate])
  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone].gsub(/[-(). ]/, ""))
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding) #binding: An instance of binding knows all about the current state of variables and methods within the erb file

  # save_thankyou_letter(id, form_letter)

  key_count(date.hour, peeak_time)

  key_count(date.strftime("%A"), peak_day)
end
