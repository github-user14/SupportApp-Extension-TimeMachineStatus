# SupportApp-Extension / Time Machine Status
WIP!
Only tested with macOS Sonoma 14.3

Used with the Support App:
https://github.com/root3nl/SupportApp

Requires the SupportHelper to run the script as root with the OnAppearScript functionality.

Place the script in /usr/local/bin/ and configure Support App to run the scrip and to show the ExtensionA field.

Enable Extension A

<img width="345" alt="image" src="https://github.com/github-user14/SupportApp-Extensions/assets/158499136/bd0e4d9d-6cba-42e5-a71f-5c5d6279db57">

Extension Title

<img width="320" alt="image" src="https://github.com/github-user14/SupportApp-Extensions/assets/158499136/374fb6d3-9c1d-4d68-96b9-17c420e61282">


OnAppear Script

<img width="318" alt="image" src="https://github.com/github-user14/SupportApp-Extensions/assets/158499136/d5226839-4278-4732-808f-11617f058341">

Time Machine status

<img width="189" alt="image" src="https://github.com/github-user14/SupportApp-Extensions/assets/158499136/7f4e0158-add4-4c14-8e5b-30addf043969">

By default the script enables the orange warning when:
- Time Machine is disabled
- when no backup has been created yet
- the last backup was created more than 7 days ago 
- the backup is not encrypted
