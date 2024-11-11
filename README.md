<img src="https://github.com/user-attachments/assets/793e6ed3-9cf4-4bd2-881c-9cbd1fb5d94d" alt="App Icon" width="80" height="80">

# RecycleBot

[Watch the Demo](https://studio.youtube.com/video/GPy1Fqy3rkc/edit)

[Read the write-up](https://docs.google.com/document/d/1rjaJKNxIaVSYs-_fNJzyy7vzKrRo9HudbfI2gPxMyes/edit?usp=sharing)

## Prerequisites
1. An OpenAI API key
2. Xcode
3. An iOS device running iOS 16.0 or later

## How to Run
1. Clone this project onto your local computer
2. Navigate to the parent folder and execute `xed .` or double click the .xcodeproj file
3. **Add your OpenAI key** to the `Config.xconfig` file
4. Select a simulator or real device running iOS 16 or newer
   - If you are running the app on a real device, make sure that you add a signing team. To do this, click the Xcode Project (the file denoted with the blue app icon), go to Signing & Capabilites, then select your Apple ID from the list
5. Click run or `⌘R` and start recycling!

## Features
- Take or upload photos of objects near you to learn how to best dispose of them!
- See how many tokens you have used/money has been spent
- Change the location, so ChatGPT can give you the most accurate recycling date
- Change ChatGPT's personality (Default is professional)
