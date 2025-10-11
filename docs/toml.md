
# syntax

References:
- https://learnxinyminutes.com/toml/

# what's wrong with toml

People love it:
- https://www.reddit.com/r/rust/comments/m37zya/i_really_love_toml_files/

It's ugly as fuck, though:
- https://hitchdev.com/strictyaml/why-not/toml/

Loot at this example:

```toml
[test.qwe]
x = "y"

[test.asd]
z = "w"

# a million lines here

[test.qwe.zxc]
m = "n"
```

How the hell are you supposed to know that `test.qwe.zxc` exists?
You are reading the file line by line. You encounter the `test.qwe` section. You read it, it ends, completely different section starts.
A million lines later there is a continuation of `test.qwe`. How do you know that it will not be continued even later?

TOML has no spatial structure, unlike any other configuration language.
Most languages have "order of keys in the map doesn't matter" rule.
But TOML raises it to "kays can be placed outside of the map", which is completely unreadable.

I don't understand one thing: why does TOML has sections at all?
It seems like TOML wanted to be explicit, and avoid cases when you need to look at the context
to understand current placement in the config tree. You only need to look at the section name.
If section is `why.the.hell.'am.i.doing.this'.in.toml.what-the-hell-is-wrong.with.me.'this.is.ugly'`,
then you can clearly understand that this is a sibling section of `why.the.hell.'am.i.doing.this'.in.toml.what-the-hell-is-wrong.with.me.oh`,
which is not a section at all. How convenient!

But wait... Sections can be multiline! You still need to look a few lines up to find a section.
Or sometimes it's not a _few_ lines up, sometimes it's many lines up.
It's the dreaded _context_! Oh no!

We could imagine a modification of TOML that looked like this:

```go
test.qwe.x = "y"
test.asd.z = "w"
// a million lines here
test.qwe.zxc.m = "n"
```

This is equivalent to the first example.
It's even shorter shorter in this case.
And it is more explicit.

The number of times section keys are repeated is still `O(N)`, where N is the number of keys.
It can be 10 times bigger for complex configs with many keys on a map, but it's still `O(N)`.

It does completely eliminate the need to look for context, because now you are guaranteed to get your context in the same line.

Most importantly it highlights how ridiculous it is to be able spread parts of one object over the whole file.
Which is like, the whole idea of TOML.

Also, you are naturally forced to follow bigger indentation for more nested keys.
Just like... Oh my god, just like all the other configuration languages that TOML is claiming to be better than.
Also, in the real world TOML config files also follow indentation rules.
It's as if all the other languages have indentation for a reason...
Oh no, we again proved that TOML is stupid and unreadable.

Poor TOML. Just let it die already.
