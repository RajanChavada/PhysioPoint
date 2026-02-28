## What problem is your app playground trying to solve and what inspired you to solve it?

26% of Canadians have needed physiotherapy and gone without it. The number one reason: they couldn't afford it. A single session costs up to $200 out of pocket, and research shows that people with lower incomes, immigrants, and visible minorities access physiotherapy at significantly lower rates than the general population. This I noticed was the unaffordable barrier for my parents and relatives who suffer from chronic pain. 

My brother-in-law's parents both live with chronic pain from physically demanding jobs. His father has a metal plate in his arm. They manage with YouTube videos, no feedback, no structure, no clinical oversight. My cousin dislocated his knee, paid $150 per session, and now does those exercises alone with no way to know if his form is safe. Studies show 73% of patients don't complete home exercise programs without guidance, not because they don't want to recover, but because unsupervised rehab is hard to trust.​

I wanted to create a way to understand what hurts, build a personalized rehab schedule, and use ARKit body tracking to measure joint angles in real time to perform the same assessment a physiotherapist performs manually, because recovery should not depend on what someone can afford.


## Who would benefit from your app playground and how?

PhysioPoint is designed for individuals who need physiotherapy or rehabilitation but face barriers like cost, access, or intimidation around clinical care. It empowers people to begin and maintain recovery on their own terms by providing structured guided programs that fit into their real busy lives. 

For the working professional who spends long hours on their feet only to return home to additional responsibilities, traditional physiotherapy can feel impossible. With limited time and unaffordable, $200+ sessions. Physiopoint offers programs that fit into their schedules so that they can prioritize recovery without sacrificing income and family time. 

For Injured athletes without employer benefits or insurance, as well as individuals going through rehabilitation Apple's ARKit ensures their form meets the same standard as a clinical grade physiotherapist would enforce, reducing the risk of re-injury and building confidence. Enabling them to complete exercises safely at home without financial strain.

For elderly individuals who find technology intimidating, or perceive rehabilitation as unaffordable. PhysioPoint incorporates an Accessibility mode, designed with larger buttons, simpler UX and guided sessions requiring only an IPad and partner willing to help to make recovery more approachable/managable. 

PhysioPoint removes the barrier to start rehabilitation while supporting, not replacing, traditional physiotherapy care. 

## How did accessibility factor into your design process?

Accessibility was the foundation for PhysioPoint and was shaped into every design choice. The target users included elderly individuals, people recovering from serious injuries, and those who simply experience cognitive fatigue during rehabilitation. This demanded a different approach than just building a technically adverse system. 

The most significant factor was a dedicated assistive access mode, completely shifting the UI with custom SwiftUI environment keys to transform the interface into a simpler layout, with larger buttons, easier navigation, and scaled touch targets to minimum of 44x44pt as per Apple's human interface guidelines. Making the interaction for users who find standard apps highly overwhelming, that much more approachable

Next, During AR sessions using the devices camera, by acknowledging that most users won’t be alone, PhysioPoint provides on screen cues that prompt the helper to read aloud, guiding the patient to perform the exercises correctly and safely. After sessions, a summary page is created to distill the performance into plain language rather than raw data to encourage further steps and add positive reinforcement. 

Finally, PhysioPint fully supports Apple’s VoiceOver and system read-aloud features, this means users who struggle with reading text are also a part of the same guided experience as everyone else.

## Did you use AI tools?
I utilized LLM’s and Generative AI as a collaborative research and design partner. I used Gemini and Perplexity to synthesize complex documentation for ARKit, allowing me to architect a robust file structure and class abstraction layers. In my IDE, I used AI to assist with specific SwiftUI syntax and scaffolding for complex UI components. By using a concept I call the teacher/student model enabling me to delegate tedious tasks to the IDE specific model and rapidly develop my own iterations allowing me to completely use the full capabilities of the SwiftUI.
These tools helped in learning about over 100+ SwiftUI components. The research led to the integration of Apple's Human Interface Guidelines and VoiceOver. Specialized components and ARKit integrations were mastered. Third-party component catalogs were used to incorporate  pre-built elements in the final application.
Additionally, I used generative image tools to create custom medical illustrations and glassmorphic icons based on my design specifications. While AI supported research, documentation synthesis, and occasional syntax guidance, I was fully responsible for the application’s architecture and logic, the integration of Apple frameworks, the development of the AR posture-tracking system, and the complete end-to-end implementation within Swift Playgrounds.

## What other technologies did you use in your app playground, and why did you choose them?

The core of PhysioPoint is ARKit (ARBodyTrackingConfiguration) which tracks the full human skeleton in real time, it was used to verify the form through live angle calculations based on the specific exercise being done. The raw joint positions are processed using Apple’s SMID framework for vector dot products and cross products, powering the AngleMath.swift. The RealityKit was used to render the 3D wireframe skeleton overlay to give the users visual biofeedback, this was critical in understanding how their movements were interpreted during an exercise. 

SwiftUI also drove the entire interface, NavigationStack, EnvironmentObject, and custom environment key branch to switch the app between standard and assistive access mode without duplication of logic. This was important because the application catered to accessibility for our target user groups. 

The application uses on-device foundation models which are compiler-gated with #available in the case the user has iOS 26/XCode 26, but also gracefully degrades to a rule-based engine on Swift Playgrounds this was done to allow the user AI rehabilitation agent so people could ask direct questions about their pain. 

Finally, AppStorage was used to persist all rehab plans on-device without depending on any networks, serving all the plans to the user. 

## Have you shared your app development knowledge with others or used your technology skills to support your community? Describe specific activities and impact. Note: This is about you, not your app.

My commitment to technology lies in its power to empower others. I focus on democratizing visibility for small business owners who are often overshadowed by corporate chains. To address this, I built Plyce, an open-source React application that connects people seeking hidden-gem restaurants with local businesses offering unique experiences.
The idea emerged from a common frustration: when my friends and I searched for places to eat, TikTok heavily shaped our choices, yet many deserving small businesses lacked exposure. To bridge this gap, I leveraged Google Cloud’s Places API and developed a discovery algorithm that surfaces locally trending restaurants by analyzing TikTok-driven engagement and mapping it to real-world locations.
After sharing Plyce on LinkedIn, the platform grew to over 1,300 users across Canada, the United States, and beyond. More importantly, it helped amplify visibility for independent businesses within their communities.
By making Plyce fully open-source, I transformed the project into a learning resource, sharing both my code and development process. For me, technology is not just about building products, It’s about creating tools that enable others to thrive.


