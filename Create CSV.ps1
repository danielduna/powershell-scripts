# List of users
$users = @(
    "Olivia Meredith",
    "Dean Hockley",
    "Hattie Marshall",
    "Caryss Pickavance",
    "Lydia Bruce",
    "Huw Richards",
    "Isabelle Cascarino",
    "Suzie Barron",
    "Karen Lawrence",
    "Emily Stone",
    "Carly Thompson",
    "Irina Smith",
    "David Sandbrook",
    "Emily Moore",
    "Finlay Eldridge",
    "Emily Littlejohn",
    "Rebecca Nelmes",
    "Julia Bunko",
    "Will Griffiths",
    "Jessica French",
    "Jeanette Whitfield",
    "Claire Matthews",
    "Abigail Hicks",
    "Toby Swindells",
    "Sophie Richardson",
    "Zara Dunford",
    "Diane Holmes",
    "Helen Lee",
    "Megan Roots",
    "Aileen Roberts",
    "Manu Bedinadze",
    "Fabienne Kentish",
    "Sophie Davidson",
    "Sophie Hjelte",
    "Emma Gardner",
    "Kate Stevens",
    "Juliet Pritchard",
    "Lajla Turner",
    "Lucy Hardy",
    "Abigail Hicks"
)

# Create and open the CSV file
$outFile = "C:\IT\TG.csv"
$csvContent = "email,role"

# Generate user data and append to CSV content
foreach ($user in $users) {
    $email = "$($user.ToLower().Replace(' ', '.'))@carterjonas.co.uk"
    $csvContent += "`n$email,Member"
}

# Write CSV content to file
$csvContent | Out-File -FilePath $outFile -Encoding UTF8

Write-Host "CSV file '$outFile' created successfully."
