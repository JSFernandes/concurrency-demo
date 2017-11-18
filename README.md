# Concurrency demo

This project is a demo of concurrency testing done in RSpec.

To achieve this, the project makes use of regular forks, and of the [fork break gem](https://github.com/forkbreak/fork_break).
It also cleans up the use of fork break with a methodology based on [this post](https://coderwall.com/p/cwergq/testing-concurrency-with-rspec-the-easy-way).

I recommend following the repository's commit history in order to understand how the testing evolved in the project.

## Running the project

To run this project you need to have Ruby and PostgreSQL installed. There is no specified `.ruby-version` file,
but I expect it to work with with anything 2.2+.

Install the necessary gems:

```
  bundle install
```

Setup the database:

```
  bundle exec rake db:create
  bundle exec rake db:migrate
```

Run the tests:

```
  bundle exec rspec
```
