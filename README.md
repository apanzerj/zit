# Zit

Helps manage Pull Requests and branches in git while sending automated (private) updates to the Zendesk agent(s) who are working with the customer.

# Install

    $ gem install zit

## Usage
### Zendesk
zit init -c zendesk -t [TICKET\_ID]

Use this to start your work. Put your ticketid where it says TICKET\_ID and it will create a new branch. It will also find the ticket in Zendesk and add the following comment: "A new branch has been created for this ticket. It should be named [new\_branch\_name]."

zit -r --c zendesk

Use this when you are done and it will create a pull request (in a new browser window, that you can edit). The PR will have the replication steps from the comment in the ticket that a specific tag.

### Jira
zit init -c jira -p [PROJECT] -i [ISSUE\_ID]

zit -r -c jira
Make sure you have the correct branch checked out.
