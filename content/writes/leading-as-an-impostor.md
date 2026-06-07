+++
title = "Leading as an Impostor [talk transcript]"
date = 2026-06-07
+++

<aside>

This is a modified transcript of a talk I gave at Datadog. 
Some things don't transfer as well since this is, you know,
not actually a talk.

</aside>

> If I was good at my job what would I be doing _right now?_

This is a question I ask myself when I’m in weird situations when I’m not sure what to do. 
Which is a thing that happens fairly often. The phrase gives me a way to recognize that 
I am actually not feeling great about myself, and gives me the space to try to do something 
different and better.

This is about how I try to work and is a reflection on the kind of software engineer 
_I_ am, and will hopefully help you if you’re facing uncertainty as well. 

<span class="small">(I'd be doing this talk.)</span>

## Welcome to Datadog, figure it out

When I joined Datadog, my manager pointed me at the onboarding team and said, 
"go there and help, it's important." 

The entirety of my onboarding experience with him: here’s a list of people, 
here’s a project that’s happening, go _do that_. We had worked together before 
so he did the responsible thing and threw me into the deep end. 
I was supposed to be able to figure it out, _that's my job_. I was new to the company, 
the team, the stack, the product, etc. 

There's something forgiving about being new — you're given leeway to take 
your time. I got to sit in on meetings and not have to contribute much for 
a bit, I met a bunch of people, had a lot of conversations, learned things. 
I took a lot of notes. 

The question was still there... "what do I do?", but first I needed to know: 
what was _going on_; and then _how it was going on;_ and 
_why it was going on._ 

I didn't want to get in the way of the work folks were _already_ doing. 
And if I was going to help, I needed trust from the folks already doing the work, 
obviously that helps me trust what I'm doing since they're the ones who have been working 
on things, they're the ones who are the experts on the space. 

I didn't have a lot of time, I knew that I had 3 months-- we were going to have 
another baby. So my goal was to make a tangible impact within that time period and 
if I didn't, I'd have done nothing for the first 6 months of my job and that would suck.

This is a harsh way to look at myself and feel but from the feedback cycle and evaluation and 
compensation and just feeling good about my time there, I would want to have had an impact and 
not come back and then start over entirely _again_.


### It figures me out, too

When you start somewhere, it's the same, "is this person good?", 
"what are they good at?", "why are they here?", "what are they going to do?"

This is true for everyone new on a team, and new at a company and new on a project. 
When you start somewhere at a higher level, that expectation is higher, 
you have to have impact sooner. 

- "What does a Staff Engineer even do?" 
- “Why are they a staff engineer?” 
- “Who is this guy?" 
- "Why did leadership ask this person to join _my team_?"

## Origin 

<aside>

I was originally going to talk about [Single Step Instrumentation][ssi] and what my version of 
help was chronologically, but I’m going to go back in time first.

</aside>

> "If I was good at my job what would I be doing right now?"

The first time I really articulated this thought to myself was in my last job, 
I was a new manager, managing a team that hadn't had consistent management. 
This was at CashApp, and it was the traffic team, just to be specific. 

It was "well understood" they were really smart but the team was underperforming, 
but no one knew how they were underperforming, it was _vibes_, they were working 
on a lot of super important projects, and I was there to help them? I had no idea 
what I was doing. I didn't know how to _manage_ a team into a better situation. 
I'd never helped in that way before.

I was stuck, I was full of dread and anxiety and I couldn't and shouldn't be doing 
any of the usual "engineer” things to help this situation, in some way, you have 
to help the team figure things out for themselves, but guide them there, wherever 
way that is so that they learn how to do that for themselves in the future — 
and that’s growth. But you have to do that understanding the general power dynamic 
of being their “boss.”

_"If I was good at my job what would I be doing right now?"_

After some time fighting myself, I got __here__. I knew that there were people 
_out there_ that were good at this kind of thing, in fact, I’d been on teams that 
were in similar situations, and needed help, and I might have even helped, but 
this was different. 

What would someone who knew how to solve this problem do? 

It gave me permission to admit to myself that I wasn't doing a great job. Even if 
it was OK from the outside because I was a new manager, I didn't feel like I was 
doing a good job, and that could kind of get me to forgive myself, and give me an 
outlet for that experience. 

### People just want to be people

What does the team need? What do the stakeholders— what do the folks who think 
the team is not doing well need? How would someone else solve this problem? Can I do a 
little bit of that? Then can I do more of it?

Of course, the answers eventually were something like: more communication, stop working 
on things you don't need to work on, get the team to stop doing things that were 
contributing to this _rut_ they were in, in a way that helped them _learn_ they 
_could_ do this, as well, which is also what I was trying to do for myself at the same time.

## Etsy (before CashApp)

I realized that even before the CashApp stuff, and before I had this question to 
help myself, I was kind of already doing it. It just wasn't intentional or conscious. 

I used to work at Etsy, I was there in total for almost 7 years. 5 years in, 
The CEO was fired and there were a few rounds of layoffs. And when you have layoffs, 
other people leave too, so obviously there were fewer people, and more importantly, 
there were fewer people that did specific kinds of work. I did not leave.

Later that year we had a team of product engineers working on a feature that hadn't 
worked on anything like that before— they were transferred from one department to work 
on the user facing product. I was asked to help them— there were a few weeks before 
the deadline to ship— it was a holiday promotion, so like a real deadline not an end 
of quarter announcement that can say “coming soon”.

I remember thinking that there were two bad outcomes:
- this feature doesn't actually ship
- the team felt like the work was taken away from them because someone else came 
  in to get it done because they weren't good enough

I had context on how to build products at Etsy but not how this team worked, 
what they were building, and what they needed help with.

I also didn't have their _trust_. I was someone forced onto their team — a team that had been 
working together without me just fine.

### Tests

The one thing that immediately gets dropped from scope when you're under a tight deadline 
is tests.

I wrote a ton of tests, and that ended up saving a lot of time because the team would have 
to manually validate their changes every time they made them.

Tests give an engineering team _confidence to make changes and move faster_. It also helped 
me understand what they were doing, and influence their behavior with a different way than 
just saying, "I think we should do it like this because I’m senior."

In a way I did their “unfun maintenance” and used that to make their work “more testable” 
and then more robust, and continue to slowly introduce patterns/changes. So they could both 
work faster since they had to do manual testing less often, and the quality of their work 
went up since the code was now safer to change.

They built the features. They shipped the product. They succeeded as a team. They won. 
They got recognition. I just helped.

## Coming back (from parental leave)

Here we are, back in the future, at Datadog, APM Onboarding and Single Step Instrumentation.

Fast forward six months into Datadog and there’s a new team in place! Injection Platform, 
with only one person remaining from the squad — with everyone moving on to other projects
at the company.

I thought that when I went on leave — I left all of these ideas that would hopefully be 
worked on, and I would move on to something new — but Kubernetes didn't move. Linux is 
about to GA, Kubernetes is just hanging around. It has to GA as soon as possible. There 
is no plan. 

Even though I _thought_ my job was originally to do some productive things and then move 
on to another part of the org to kind of onboard and learn more, the thing that needed 
to happen here is a plan of execution. It was pretty obvious, I had the most context, 
it was a nice and natural fit, I didn't fight the inertia. 

The big problem was there was no one on the team working on it, they hadn't hired 
someone for that yet, and in order for this to _work_ we needed a plan and buy in — 

The team was going to own this long term, not me. No individual really owns a piece 
of software at a company. 

I knew that working on this and shipping to GA was going 
to be a thing I did _right now_ not necessarily the space that I was going to occupy 
forever, I shouldn't be the kubernetes-single-step guy — we could hopefully get another one. 

We hired someone, in NY, my manager told me he knew k8s, and I kind of stole him to shadow 
and work with me on the features— we needed someone from the team to own the feature, 
and be setup to own the general space longer term. 

Luckily, he was great and he sponged everything up as quickly as it was available, was able 
to deliver the work and now is the person on the team who owns all of this. 

I stopped writing code on the project except for small things — he shipped the big features, 
he worked across team with the container platform, he got it done. Him and the team succeeded. 
For me, a sign that I'm doing my job well, is that other folks succeed and I don't 
need to be there anymore. 

My role shifted from “earn trust with a new team" to “lead new team member to 
own the space” — from implementation to coaching and review and design to trying to step 
back and make room for somebody else.

## What now... 

And then I was in limbo. 

A pattern I've noticed is that this is a mildly compulsive and anxious behavior for me, 
I've been doing this _for years_ and can finally describe that I go into these cycles 
of certainty and uncertainty as a function of being me. 

_I’m_ continuing to put myself in a position as an impostor. I'm doing this to myself.
Parts of this are very much not fun. I give up immediate expertise, I give up immediate 
productivity, I give up the gratification of being able to ship features and gain and 
keep momentum, it just sometimes kind of _stops_. 

No flow state. 

The positives are I work with a _lot of people_ and unlike being a contractor, I get to keep these 
relationships, I stay at the same company. It's a lot of discomfort traded for gaining context and 
expertise at more of Datadog-- which compounds over time. 

---

But yeah, I was still in limbo. My manager asked me to check the [service remapping][remapping] project— 
super ambitious, super important, huge in scope. I showed up a stranger again. With a bunch of 
people who already had working relationships and trust. I needed to figure out how to fit in. 

There were great people who knew the domain deeply, and there was already senior engineering 
leadership from a prolific product engineer who has been at Datadog for a long time — who knows 
a ton about literally everything. Again, there were _vibes_. There was uncertainty coming 
from how folks outside of the squad were looking at the effort, and the team needed full 
support from engineering and product leadership to move forward with the plan because of 
how massive an undertaking it was.

The gap was clarity between the team and leadership — everything else was there as well 
as it could be. I put together a document with the team that coalesced the risks and 
plan that was based on the work they were already doing. It was a nice doc. That was it.
_They didn't actually need me._ Anything I would add might actually be a detriment to 
the success of the project. The most helpful thing I could do was stop helping. So I stopped. 

This was hard because, _again_, I didn't have a “thing to do.” My boss had just asked me 
to work on maybe the most important thing at the time, and I didn't. 

### Despair?

When I talk about these ups and downs, the downs can still feel like despair. I've been 
through these cycles a lot so it just gets a little easier. It was my wife who once actually 
looked at me and said: 

"So you’re having a hard time right now? Okay, let’s check on how 
you’re doing in a few weeks, pretty sure this happens a few times a year. This is normal for you-- 
when are you going to figure this out?"

## Curiosity, Empathy, and Trust

There are a few things out of these examples (and there are more) 
that I’d want for folks to take away.

- If things aren't going well right now, that’s just a thing that’s happening right now. 
  We do this in post-mortems, retros, etc, but this is true for introspective things as well. 

- Thinking about what other people are really good at is a fun way to think about what 
  you’re good at, too. 

- If you’re trying to figure out what to do or how to grow, sometimes it’s by looking 
  around you and seeing what the people around you are really good at and trying to copy that.

- You can also see if there’s something that people around you _aren't_ doing that feels like 
  a gap and step into that. You don't have to be perfect at it. No one is doing it! 

- You can help support your teammates in many ways. With docs, or tests, or just having 
  a conversation, or setting up that meeting to discuss the thing everyone has been avoiding. 

- Doing nothing is a _choice_ and even though it feels like a default. When you realize that you 
  can _choose_ to wait until you have a better option than what you have now, it’ll give you 
  the space and time to see it. First, do no harm.

- Seeing what someone is _not doing_ is hard.

### How

_How_ is equally if not more important than what. It’s not just what, it’s how. 
And _how_ you approach work models how other people approach their work. Curiosity, empathy, 
trust — these are things you show people through the work you do and hopefully encourage 
the same kind of behavior in the people around you. _How_ is what you show when you show up. 

> If I was good at my job **how would I be doing it**?

[ssi]: https://docs.datadoghq.com/tracing/trace_collection/single-step-apm/
[remapping]: https://docs.datadoghq.com/tracing/services/service_remapping_rules/
