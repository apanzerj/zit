# Zit


Helps manage Pull Requests and branches in git while sending automated (private) updates to the Zendesk agent(s) who are working with the customer.

# Install

    $ gem install zit

# Configuration

Almost all configuration settings are stored in ~/.zit in YAML format. The default config, shown below, is in ruby hash for easier reading.

The default config is:

````ruby
{
:gitname                      => "doody",         # your git username
:base_repo                    => nil,             # base github repo
:last_branch                  => nil,             # the last branch you were on when you ran init
:last_system                  => nil,             # the last system you specified when you ran init
:repsteps_tag                 => "macro_1234",    # replication steps tag (see below)
:include_repsteps_by_default  => true,            # include replication steps by default
:zendesk_url                  => nil,             # The url of your Zendesk instance
:jira_url                     => nil,             # The url of your jira instance
:settings_version             => 1.0              # ignore this right now.
}
````

The only settings that MUST be set in this file are: zendesk\_url and jira\_url

In management.rb there is a method called "get\_repsteps". In there, you'll find this line:

````ruby
next unless audit.events.map(&:value).join(" ").include?(macro_tag)
````

The "macro_tag" refers to the setting in ~/.zit called repsteps\_tag (which refers to a tag that is added with a comment on a series of replication steps). This is only workable for Zendesk tickets as Jira issues do not have tags. If the repsteps\_tag is not found on any comment, you'll be given a list of all comments to pick amongst. In addition, the setting include\_repsteps\_by\_default can be swtiched to false in order to skip this process all together.

Finally, you'll need to have 5 environment variables set: zendesk\_user, zendesk\_token, jira\_user, jira\_pass, and optionally your gh_api_key which can be generated here: https://github.com/settings/applications (under "Personal Access Tokens")

The GH api token is only needed if you want to use the zit update function.

# Todo

1. Dry things up.

2. Fix up docs (the stuff below here is stale)

## Usage

### Zendesk

**Description:** When used with Zendesk the syntax is as follows:

    $ zit init -c zendesk -t [TICKET_ID]

Use this to start your workflow. The init command will initialize the repository. The -c/--connector flag will tell Zit which system you are talking to, zendesk or jira. The -t flag passes in the Zendesk ticket id number.

**Results:** Zit will create a new branch with a name composed of the format:

name/zd[ticket\_id]

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

Lastly, once you have submitted your pull request you can type:

    $ zit update

To have Zit update the ticket/issue with the comment:

PR: {PR URL}

For the relevant pull request.
