# Zit


Helps manage Pull Requests and branches in git while sending automated (private) updates to the Zendesk agent(s) who are working with the customer.

# Install

    $ gem install zit

# Configuration

1. Inside lib/zit.rb there are some constants defined. BASE\_REPO is the url for the repository you are working with, for example: https://github.com/apanzerj/zit.

2. In management.rb there is a method called "get\_repsteps". In there, you'll find this line:

    ````ruby
    next unless audit.events.map(&:value).join(" ").include?("macro_1234")
    ````

    Where it says "macro\_1234" you should change this to the specific tag you will use when you want to denote replication steps to the development group. This will help Zit find replication steps on a ticket. 

3. Finally, you'll need to have 4 environment variables set: zendesk\_user, zendesk\_token, jira\_user, and jira\_pass

# Todo

1. Find a better way to manage configuration

2. Zendesk comment selection mirroring the way Jira comment are selected.

3. Dry things up.

## Usage

### Zendesk

**Description:** When used with Zendesk the syntax is as follows:

    $ zit init -c zendesk -t [TICKET\_ID]

Use this to start your workflow. The init command will initialize the repository. The -c/--connector flag will tell Zit which system you are talking to, zendesk or jira. The -t flag passes in the Zendesk ticket id number.

**Results:** Zit will create a new branch with a name composed of the format:

name/zd[ticket\_id

For example:

Github Username: apanzerj
Ticket ID: 12345

    $ zit init -c zendesk -t 12345

New branch name: apanzerj/zd12345

In addition, Zit will "pingback" the Zendesk ticket with a private comment:

"A branch for this ticket has been created. It should be named apanzerj/zd12345."

Once you have completed your work on the branch, you can use:

    $ zit ready -c zendesk

Zit will detect the currently checked out branch and then pingback the ticket with a private comment:

"A pull request for your branch is being created."

Zit will then call:

    $ open https://github.com/....

such that your default browser opens to the correct repository with a valid PR waiting.


### Jira

Much of the details above are the same for Jira as they are for Zendesk with a few important distinctions:

When starting the workflow you'll want to do this (keeping with our example from above):

    $ zit init -c jira -p HD -i 123

This will create a new branch for issue HD-123 where HD is the project and 123 is the issue.

Pingback does not make a "private comment"

When finished with your branch you can still type:

    $ zit ready -c jira

But Zit will give you a list of comments to choose from so you can decide which one you want to be included as your pull request description. 
