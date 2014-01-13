# Zit

Basically I got tired of constantly making a branch, naming it right, including relevant garbage in the PR. So I made this as a weekend project. VERY work in progress.

## Installation

Add this line to your application's Gemfile:

    gem 'zit'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zit

## Usage

zit init ticketid

Use this to start your work. Put your ticketid where it says ticketid and it will create a new branch. It will also find the ticket in Zendesk and add the following comment: "A new branch has been created for this ticket. It should be named [new\_branch\_name]."

zit ready (finish your work)

Use this when you are done and it will create a pull request (in a new browser window, that you can edit). The PR will have the replication steps from the comment in the ticket that a specific tag.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
