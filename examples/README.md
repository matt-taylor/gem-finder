# Examples

## [Single Validation Example](git_tag.yml)

This is the most basic example. GemEnforcment provides some sane defaults for you to get going quickly. With minimal information, you can start enforcing gem versioning in your script, gem, or application!

## [Enforcement with Multiple Behaviors Example](multiple_behavior.yml)

Multiple behaviors can be super helpful when you want to send a warning before the nuclear option of exiting or raising an error. Using multiple behaviors you can stack the experience and layer multiple warnings on when the Enforcment becomes more forceful

(Also shows a basic example of how a single config can support multiple gem validations)

## [Git Tag with SemVer Example](git_tag.yml)

### Git Tag
Git Tags allow you to query the version list from git tags. This can help the gem you care about is not in a gem source but rather just in git

### SemVer Version Enforcement
SemVer versioning enforcment allows you to tailor the Gem Enforcement. Based on the Major, Minor, and/or Patch version of the current gem, you can set individual requirements to meet your needs
