VAR knows_chap = false
VAR knows_premium = 0
VAR collection_quest = ""
VAR credits = 0
VAR loaned_credits = 0
EXTERNAL take_out_loan(value)

{knows_chap:
    -> return_greeting 
}

Welcome to your integrated exploration, extraction, and enslavement experience. 

Just kidding. Just kidding. 

Welcome to your brand  new space-faring mansion.

You can call me CHAP and I'm here to answer any question you have as well as facilitate any of yours and Mimas Travel Ltd mutual interests.

-> pre_chap

=== return_greeting ===

{Oh hi there skipper!|Welcome back, don't be a stranger!|Fancy meeting you here!}

-> pre_chap

=== pre_chap ===
{How can I help you today?|What do you need?|What's on your mind?|Any inquiry?}
-> chap1

=== chap ===
{What do you need?|What's on your mind?|Any inquiry?}
-> chap1

=== chap1 ===
+ [Who are you?] Me? I'm CHAP! Didn't I tell you? -> chap
+ [Tell me about this mansion]
    Oh, yes. You are sitting in an X900. A marvel tailored to your every need.
    
    Though this one isn't exactly new and I guess, well it still says it is tailored to your every need.
    
    And when I say every need, I should perhaps expalin. The vessel comes equipped with all upgrades, amenities, and experimental technology pre-installed.
    
    Just a small fee to unlock premium features.
    ~ knows_premium = max(knows_premium, 1)
    -> chap
+ [I have question about the rooms] -> rooms
+ {knows_premium > 0} [Premium Program] Oh yes glad you want to know more about our extended catalogue of marvelous offers -> premium_programs
+ {knows_premium > 1} [Indenture Program] -> loans
+ [What's up with these months?] -> calendar
+ [Nothing really] I wont hold it against you -> END

=== calendar ===
Oh, forget you are still an Earther!

In space each day takes the same amount of time as a standard day on earth, but it is devided into 10 hours, each with 10 minutes, and 10 seconds. 

But we usually just use decimal days like it's 0.32 in the morning!

Then there are 24 days in each month and there are 10 months to a year, which is much shorter than earth years.

Yeah I don't know why that is either, but it is great! It allows us to collect rent more often!
-> chap

=== rooms ===
Then we have each individual room. I'm happy to answer particular questions about any of them:
-> rooms1

=== rooms1 ===
+ [Nav]
    Yes this is where you chart out regions of space to explore.
    
    It is easier with maps and leads about where to go, and well also a good idea to have engines and fuel enough to get there.
    
    -> rooms
+ [Mission Ops]
    Flying around the galaxy is fun and all, but without mission ops there's no sending out robots to explore the sites you've navigated to.
    
    Quite lazy honestly to let the robots do all the work while you kick it back here with a cup of tea and a bisquit.
    
    -> rooms
+ [Living Quarters]
    Most humans, feel more comfortable with a bed, a shower, kitchenett and some personal space.
    
    {
        - collection_quest == "":
            What piece of useless detritus will you collect to make this ship feel cozy?
            -> collection
        - collection_quest == "rocks":
            And in your case a bookshelf filled with rocks, rocks and rocks.
        - collection_quest == "alien artifacts":
            For you this is alien gadgets with unknown purpose because risk assessment is not what you do.
        - collection_quest == "mementos":
            You though, you need to fill your space with pieces from other's lives to feel at home. 
    }
    -> rooms
+ [Materials Lab]
    You never know when something needs breaking down into its smallest components.
    
    Or when a complex carbohydrate compound is needed.
    -> rooms
+ [The other rooms] -> rooms2
+ [That's all] 
    -> chap
    
=== rooms2 ===
+ [Printers]
    Need more shelfing? Need more storage containers for radioactive materials?
    
    Need a new robot because you risked it and didn't take proper care of your last one?
    -> rooms
+ [Infermary]
    The place you can go if your little tummy aches or where a poor ailing robot can be put back together again.
    -> rooms
+ [Storage Bay]
    Should you be overly frugal or absent minded enough to not buy into our other premium programs, you probably will need somewhere to store all things you gather. 
    
    Right?
    ~ knows_premium = max(knows_premium, 1)
    -> rooms
+ [Engine Room]
    Some people are content to just stay in one place and explore silly things like their emotions and armpits.
    
    But you, who invested in a spaceship must surely be interested in moving around.
    -> rooms
+ [The first rooms] -> rooms1
+ [That's all] 
    -> chap
    
=== collection ===
+ [Oddly shaped rocks!] 
    Oh you are one of those. Well at least it's inorganic and quite sanitary.
    ~ collection_quest = "rocks" 
    -> lock_collection
+ [Lost personal mementos]
    Great, just great.
    
    Let's be on the lookout for the most unhygenic, dirty, worn out generic plushie - because it tells a personal story. Or something. 
    ~ collection_quest = "mementos"
    -> lock_collection
+ [Alien artifacts]
    That's not the safest way to live. You never know what they do.
    
    But at least they could be valuable.
    ~ collection_quest = "alien artifacts"
    -> lock_collection
    
=== lock_collection ===
Are you sure {collection_quest=="rocks":rocks}{collection_quest=="mementos":other people's shit}{collection_quest=="alien artifacts":alien artifacts} is your thing?

+ [YES!] -> rooms
+ [No, just kidding]
    Oh maybe you are collecting something more immaterial?
    
    Like
    
    LAME JOKES?
    ~ collection_quest = ""
    -> rooms

=== premium_programs ===
You see, it would be a very bad business to sell overly expensive ships that Naive Natan and Entrepreneuring Ellen cannot afford. 

It's also, absolutely not practical to build out a galaxy spanning service network.

So we came up with this novel solution:

The ship comes fully stocked and then the customer just has to pay a small downpayment and monthly upkeep to keep subscribing to that premium program.
~ knows_premium = max(knows_premium, 2)

+ [What happens if I can't pay] -> loans
+ [That sounds very greedy!] I know! Isn't it marvelous? -> chap

=== loans ===
If you ever find yourself in dire straits and cannot afford next months rent or cannot afford to wait before obtaining access to a particular technology, don't hesitate to ask about our indenture program.

+ [Tell me more] -> indenture
+ [Not today please] Fine, the offer still stands whenever you find yourself in trouble. -> chap

=== indenture ===
{
- loaned_credits > 0:
    Oh hello returning customer.
    
    {Did you know that the more you loan the better rates you get?|Your loyalty rating is high enough for at least one more loan. And besides, where would you run if you couldn't pay?}
- else:
    You know it is a false sentiment that the one who stands on their own legs is the strongest. It is always better to lean on a friend!
}

+ {loaned_credits > 0} [Pay off my loan]
        Oh, no, I'm sorry. We don't offer that service. Why would we want to give up on that interest you have to pay each month?
        {credits < loaned_credits: Besides, you don't even have enough to pay back the loan.}
        -> indenture
+ {lock_collection == 0} [How do loans work?] Easiest thing in the world! You pick the amount and it gets transferred to your account instantly. -> indenture

* [Borrow 1000 credits]
    ~ loaned_credits += 1000
    ~ credits += 1000
    ~ take_out_loan(1000)
    Congratulation you are now 1000 credits richer. Wasn't that easy?
    -> indenture
 + [Thank's but not now]
    Fine, but remember there's nothing shameful in relying a bit on one's friends.   
    -> chap

=== function max(a,b) ===
	{ a < b:
		~ return b
	- else:
		~ return a
	}
    
