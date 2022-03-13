"""
Applet: Reddit Image Shuffle
Summary: Display Reddit Images on Shuffle
Description: Show a random image post from a custom list of subreddits (up to 10) and/or a list of default subreddits. Use the ID in line 3 to access the post on a computer, at http://www.reddit.com/{id}. All fields are optional.
Author: Nicole Brooks
"""

load("render.star", "render")
load("time.star", "time")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("schema.star", "schema")
load("cache.star", "cache")

DEFAULT_SUBREDDITS = ["blackcats", "aww", "eyebleach", "itookapicture", "cats", "pic"]
APPROVED_FILETYPES = [".png", ".jpg", ".jpeg", ".bmp"]

def main(config):

    # Build full sub list based on user options.
    allSubs = combineSubs(config)

    # Get subreddit name and chosen post (pseudo)randomly.
    chosenSub = allSubs[getRandomNumber(len(allSubs))]
    currentPost = getPosts(chosenSub)

    # Render image/text
    imgSrc = http.get(currentPost["url"]).body()
    return render.Root(
        child = 
        render.Box(
            color = "#0f0f0f",
            child = render.Row(
                children = [
                    render.Image(
                        src = imgSrc,
                        width = 35,
                        height = 35
                    ),
                    render.Padding(
                        expanded = True,
                        pad = 1,
                        child = render.Column(
                                    expanded = True,
                                    main_align = "space_evenly",
                                    children = [
                                        render.Marquee(
                                            width = 28,
                                            child = render.Text(
                                                content = currentPost["title"],
                                                font = "tom-thumb",
                                                color = "#8899A6"
                                            )
                                        ),
                                        render.Marquee(
                                            width = 28,
                                            child = render.Text(
                                                content = currentPost["sub"],
                                                font = "tom-thumb",
                                                color = "#6B8090"
                                            )
                                        ),
                                        render.Text(
                                            content = currentPost["id"], 
                                            font = "tom-thumb",
                                            color = "#556672"
                                        )
                                        
                                    ]
                                )
                    )
            ]
            
        )
    )
    
)

# Gets a random number from 0 to the number specified (inclusive).
def getRandomNumber(max):
    seed = time.now().unix
    return seed % max

# Combines the default subs (if applicable) with any custom subs inputted.
def combineSubs(config):
    allSubs = []
    allSubs = checkCustomSubSchema("subOne", config, allSubs)
    allSubs = checkCustomSubSchema("subTwo", config, allSubs)
    allSubs = checkCustomSubSchema("subThree", config, allSubs)
    allSubs = checkCustomSubSchema("subFour", config, allSubs)
    allSubs = checkCustomSubSchema("subFive", config, allSubs)
    allSubs = checkCustomSubSchema("subSix", config, allSubs)
    allSubs = checkCustomSubSchema("subSeven", config, allSubs)
    allSubs = checkCustomSubSchema("subEight", config, allSubs)
    allSubs = checkCustomSubSchema("subNine", config, allSubs)
    allSubs = checkCustomSubSchema("subTen", config, allSubs)

    # If the toggle is set to true, or there are no custom values, add the defaults too
    if config.bool("defaults", False) == True or len(allSubs) == 0:
        allSubs = allSubs + DEFAULT_SUBREDDITS

    return allSubs

# Checks if the user entered data in the given input.
def checkCustomSubSchema(subNum, config, currentArray):
    sub = config.get(subNum, "")
    if len(sub) > 1:
        currentArray.append(buildSubPrefix(sub))
    return currentArray

# Removes any /r or /r/ characters users might have put on the sub name.
def buildSubPrefix(name):
    formattedName = name
    rIndex = name.find("r/")
    if rIndex != -1:
        formattedName = name[rIndex+2:]
    
    print("formatted sub name is: "+formattedName)
    return formattedName
    

# Gets either the cached posts or runs an API call to reddit for more.
def getPosts(subname):
    cacheName = "reddit-image-posts-" + subname
    cachedPosts = cache.get(cacheName)
    if cachedPosts != None:
        cachedPosts = json.decode(cachedPosts)
        return setRandomPost(cachedPosts, subname)
    
    apiUrl = "https://www.reddit.com/r/" + subname + "/hot.json?limit=30"
    rep = http.get(apiUrl, headers = {"User-Agent": "Random Post Tidbyt Bot " + str(getRandomNumber(9999))})
    data = rep.json()
    if "error" in data.keys():
        return handleApiError(data)
    else:
        posts = data["data"]["children"]
        allImagePosts = []
        for i in range(0, len(posts)-1):
            for j in range(0, len(APPROVED_FILETYPES)-1):
                if posts[i]["data"]["url"].endswith(APPROVED_FILETYPES[j]):
                    allImagePosts.append(posts[i]["data"])
            
        # Cache the posts for 2 hours
        cache.set(cacheName, json.encode(allImagePosts), 2 * 60 * 60)
        return setRandomPost(allImagePosts, subname)

def handleApiError(data):
    print("error :( " + data["message"])
    return { 
        "sub": "r/???",
        "title": "error",
        "id": "00000",
        "url": "https://i.imgur.com/lCkwHj0.png"
    }
        

def setRandomPost(allImagePosts, subname):
    if len(allImagePosts) > 0:
        chosen = allImagePosts[getRandomNumber(len(allImagePosts) - 1)]
        return {
            "url" : chosen["url"],
            "sub" : chosen["subreddit_name_prefixed"],
            "id" : chosen["id"],
            "title" : chosen["title"]
        }
    # This else will only run if there are no image posts in the top 30 in /r/hot for a sub.
    else:
        return { 
            "sub": "r/" + subname,
            "title": "no results",
            "id": "00000",
            "url": "https://i.imgur.com/lCkwHj0.png"
        }

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "subOne",
                name = "Custom sub 1",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subTwo",
                name = "Custom sub 2",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subThree",
                name = "Custom sub 3",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subFour",
                name = "Custom sub 4",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subFive",
                name = "Custom sub 5",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subSix",
                name = "Custom sub 6",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subSeven",
                name = "Custom sub 7",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subEight",
                name = "Custom sub 8",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subNine",
                name = "Custom sub 9",
                desc = "",
                icon = ""
            ),
            schema.Text(
                id = "subTen",
                name = "Custom sub 10",
                desc = "",
                icon = ""
            ),
            schema.Toggle(
                id = "defaults",
                name = "Include defaults",
                desc = "In addition to custom subreddits, include defaults? (ins subs here)",
                icon = "",
                default = False
            )
        ]
    )