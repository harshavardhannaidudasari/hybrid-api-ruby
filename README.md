# Hybrid API Automation Framework (Ruby)

[![CI](https://github.com/harshavardhannaidudasari/hybrid-api-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/harshavardhannaidudasari/hybrid-api-ruby/actions/workflows/ci.yml)

A small, reusable REST API test client (stdlib `Net::HTTP` + RSpec) built to
be **required by other projects**, not just run standalone. It's the
API-layer sibling to this account's `hybrid-web-mobile-*` (browser + native
mobile UI automation) and `hybrid-selfheal-*` (self-healing UI locators)
project families, and a Ruby port of `hybrid-api-java` - see "Why this
exists" below.

## Why this exists

UI automation projects regularly need to check or set up backend state
without driving the browser/app through every step (e.g. "assert the cart
total via the API instead of reading it off the page", or "create a test
user via the API before a UI login spec"). `HybridApi::ApiClient` is meant
to be `require`d by those projects for exactly that, rather than each
project reinventing its own HTTP client.

It is **not** tied to one specific API. Every setting - base URL, timeouts,
retry behavior, auth credentials - is overridable via `HYBRID_API_*`
environment variables (same convention as the other two project families'
`HYBRID_*` overrides), so pointing this at a different backend is a config
change, not a code change.

## Using this as a library

```ruby
require 'hybrid_api'

api = HybridApi::ApiClient.new # reads HYBRID_API_BASE_URL, defaults to https://dummyjson.com

# e.g. inside a UI spec, verify backend state instead of scraping the DOM:
product = api.get('/products/1')
expect(product.json['id']).to eq(1)

# or authenticate once and reuse the token on every subsequent call:
login = api.post('/auth/login', username: 'emilys', password: 'emilyspass')
authed = HybridApi::ApiClient.new.with_bearer_token(login.json['accessToken'])
authed.get('/auth/me')
```

## What's in the box

| File | Purpose |
|---|---|
| `lib/hybrid_api/client.rb` | `get`/`post`/`put`/`patch`/`delete`, optional bearer-token auth, every call routed through `RetryPolicy` |
| `lib/hybrid_api/retry_policy.rb` | Retries a request up to `HYBRID_API_RETRY_ATTEMPTS` times (default 3, 300ms apart) on a 5xx response or a connection-level error - smooths over transient blips against a real public API, doesn't mask real failures (4xx and assertion failures are never retried) |
| `lib/hybrid_api/config.rb` | Every setting + its env var override, in one place |

Built on stdlib `Net::HTTP` rather than a gem like Faraday or HTTParty - see
"Bug found by actually running this" below for why.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `HYBRID_API_BASE_URL` | `https://dummyjson.com` | Target API |
| `HYBRID_API_TIMEOUT_MS` | `10000` | Open/read timeout |
| `HYBRID_API_RETRY_ATTEMPTS` | `3` | Max attempts per request |
| `HYBRID_API_RETRY_BACKOFF_MS` | `300` | Delay between retries |
| `HYBRID_API_AUTH_USERNAME` / `HYBRID_API_AUTH_PASSWORD` | `emilys` / `emilyspass` | Credentials the auth specs log in with |

## Target APIs used for this repo's own specs

Three independent, real targets, chosen from
[public-apis/public-apis](https://github.com/public-apis/public-apis) where
noted, prove `ApiClient` isn't tied to one specific backend - the same
class, just constructed with a different `base_url:`, no framework changes
needed:

- [dummyjson.com](https://dummyjson.com) - a free, no-signup-required fake
  REST API with real CRUD semantics and a working JWT auth flow.
  (`reqres.in`, the other common choice for this, now requires a paid API
  key for every endpoint - confirmed by `curl` returning 401 on a plain
  `GET /api/users/2` - so it wasn't used.)
- [jsonplaceholder.typicode.com](https://jsonplaceholder.typicode.com) - a
  second fake REST API built for the identical purpose as dummyjson.com
  ("testing and prototyping"), sourced from the public-apis list. Its
  `/posts` CRUD semantics mirror dummyjson's `/products` closely enough
  that the same spec shapes port over almost unchanged, on a genuinely
  different host.
- [postman-echo.com](https://postman-echo.com) - an HTTP echo service used
  to directly prove each verb sends what `ApiClient` claims: the response
  reflects the exact query params/JSON body back. **Originally scoped as
  `httpbin.org`** (also from the public-apis list), but `httpbin.org`'s
  public instance was found genuinely returning `503 Service Unavailable`
  when checked live via `curl` immediately before writing this spec - not a
  one-off blip, a retry a few seconds later gave the same result.
  Substituted Postman's own echo service, which was healthy and behaves
  identically.

## Setup

```bash
cd hybrid-api-ruby
bundle install
```

## Running

```bash
bundle exec rspec
```

## What's actually been verified (last real run)

`bundle exec rspec` -> **16/16 passed** against three live targets:

| Spec | What it proves |
|---|---|
| `gets a single product with the expected fields` | `GET` + JSON parsing (dummyjson.com) |
| `respects the limit query param on the product list` | Query params (dummyjson.com) |
| `adds a product and echoes back the title with a new id` | `POST` with a JSON body (`201`) (dummyjson.com) |
| `updates a product and returns the updated title` | `PUT` with a JSON body (dummyjson.com) |
| `deletes a product and marks isDeleted true` | `DELETE` (dummyjson.com) |
| `rejects /auth/me with no token` | Protected endpoint correctly `401`s with no auth (dummyjson.com) |
| `logs in then fetches the authenticated user with the returned token` | Full auth flow: login for a real JWT, then use `with_bearer_token` on a second client instance to hit a protected endpoint (dummyjson.com) |
| `gets a single post` / `respects _limit` / `adds a post` / `updates a post` / `deletes a post` | Same CRUD shape as the dummyjson.com specs, against jsonplaceholder.typicode.com - proves it's not accidentally coupled to dummyjson.com's specific response shape |
| `echoes query params on get` / `echoes json body on post` / `echoes json body on put` / `succeeds on delete` | Each verb's query params/body genuinely arrive at the server as sent, against postman-echo.com |

## Bug found by actually running this (and how it was fixed)

The original design used the `faraday` gem, exactly like it sounds it
should. `bundle install` failed with `Installing json 2.21.2 with native
extensions / MSYS2 could not be found` - Faraday's gemspec has an unbounded
runtime dependency on `json` (`>= 0`), Bundler resolves that to the newest
release on rubygems.org, and **no Windows (`x64-mingw-ucrt`) precompiled
binary exists for any `json` gem version** - only `ruby` (source, needs a
native-extension compile) and `java` platforms. This machine has no MSYS2
toolchain installed, so the compile fails, even though a perfectly good
`json 2.7.2` already ships as a default gem with this Ruby install and
`lib/` only ever does a plain `require 'json'`.

Installing a whole MSYS2 build toolchain just to satisfy a convenience HTTP
wrapper's transitive dependency felt like the wrong fix for what this
library actually needs. Switched to stdlib `Net::HTTP` instead - zero extra
gem dependencies, same behavior, and it sidesteps the problem entirely
rather than working around it.

A second, smaller bug surfaced once the client compiled: `retry_policy.rb`
referenced `Net::OpenTimeout`/`Net::ReadTimeout` in its rescue clause but
only `client.rb` had `require 'net/http'` - since `hybrid_api.rb` requires
`retry_policy` *before* `client`, the constant wasn't loaded yet and every
spec file errored with `NameError: uninitialized constant
HybridApi::RetryPolicy::Net` before a single example ran. Fixed by adding
`require 'net/http'` directly to `retry_policy.rb` too, rather than relying
on load order across files.

## CI

`.github/workflows/ci.yml` runs the full suite against the live API on every
push/PR to `master`. No browser/emulator needed, so unlike the
`hybrid-web-mobile-*` CI jobs (which skip mobile), this one runs everything.
