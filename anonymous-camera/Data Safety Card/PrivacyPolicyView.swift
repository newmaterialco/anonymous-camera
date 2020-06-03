//
//  PrivacyPolicyView.swift
//  SafetyCard
//
//  Created by Sarah Mautsch on 29.03.20.
//  Copyright © 2020 Sarah Mautsch. All rights reserved.
//

import SwiftUI

struct PrivacyPolicyView: View {
    
    @Binding var isPresented : Bool
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer()
                ZStack(alignment: .center) {
                    Circle()
                    .frame(width: 30, height: 30)
                    .foregroundColor(Color("systemlightgrey").opacity(0.9))
                    Image(systemName: "xmark")
                    .font(Font.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("systemdarkgrey").opacity(0.9))
                    .onTapGesture {
                        self.isPresented.toggle()
                    }
                }
                .padding(.trailing, 14)
                .padding(.top, 18)
            }
            VStack(alignment: .leading) {

                HStack (alignment: .center) {
                    HStack (spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(Font.system(size: 30, weight: .semibold))
                        Text("Privacy Policy")
                            .font(Font.system(size: 32, weight: .semibold))
                    }
                     .padding(.bottom, 8)
                }
                Text("Last Updated 7th of Jan 2020")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("lightblue"))
                .padding(.bottom, 40)
                
                Group{
                Group {
                    MainText(text: "This Privacy Notice describes how Playground.ai, LLC (“Playground,” “we,” “our” or “us”) processes, uses and shares the Personal Information (defined below) that it receives or collects from users of the Playground mobile application (“App”) and any other individual or entity that may disclose Personal Information to us, as further described below.")
                
                    DotSeperator()
                    
                    MainText(text: "Please note that when using our App, information may be collected, processed and stored on servers located in a jurisdiction outside of your geographic location, which may have data protection laws that are different from (and sometimes less protective than) the laws of your country or region, such as the General Data Protection Regulation, as further described below. By using the App, you agree to such processing, transfer and use.")
                    
                    
                    HeadlineText(text:"Who We are · Data Controller")
                    
                    MainText(text: "The Playground App is a privacy-first camera application that lets users capture and anonymize photos, videos and audio directly on their phones. If you use our Sites, the data controller of your Personal Information is Playground.ai, LLC, a Delaware limited liability company. \nThe address of our main office is:")
                    
                    MainText(text: "PO Box 3878, Barrington, Illinois 60011, USA")
                    
                    MainText(text: "We also operate two websites (“Sites”) for informational purposes only, but do not collect any Personal Information from visitors to the Sites.")
                        
                    HeadlineText(text: "Questions")
                    MainText(text: "If you have any questions about our Privacy Notice, please contacts us at privacy@playground.ai.")
                    DotSeperator()
                }
                
                Group{
                    HeadlineText(text: "How we collect and process your personal information")
                    MainText(text: "Generally speaking, “Personal Information“ means any information about an individual from which that person may be identified. Personal Information includes obvious things, like your name, telephone number, email address and photographs, as well as less obvious things like your IP address, device ID and location information. Personal Information does not, however, include information from which the identity of an individual has been definitively removed (also known as anonymous or anonymized data).")
                    MainText(text: "At Playground, we believe that you own your data, and our goal is to help you get the most out of it while collecting as little Personal Information as possible. We want to be transparent in this regard, and where we do collect any Personal Information, we strongly believe in keeping your Personal Information personal, private and secure.")
                    MainText(text: "When users download the App from the Apple iOS store, we do not require them to sign up for an account or to input any information. All Personal Information about a user is stored by Apple or on the user’s device. We do not maintain a server to host the App and thus do not store any Personal Information received through the App. We may otherwise collect Personal Information when you communicate with us directly via email, as explained below.")
                    
                    //DotSeperator()
                }
                
                Group{
                    SecondHeadlineText(icon: "person.crop.rectangle.fill", text:"User Files")
                    MainText(text: "When you take a photograph, video or audio clip (each a “User File”) with the App on your iPhone, we hold onto the User File (on your device) for under a minute after it is captured, in order to enable you to preview it, but we do not store User Files. We have the capability to access User Files through the Apple APIs, however we do not utilize that capability and thus do not process such information. \nPlease note, as a general matter, that you should never upload a User File with the App – such as taking a photograph – that includes the Personal Information of any individual (other than yourself) unless you have the permission of such individual.")
                    
                    SecondHeadlineText(icon: "location.circle.fill", text:"Location Data")
                    MainText(text: "In addition, where you specifically authorize us to access location data, we hold onto this information only for a few moments in order to embed the location data into your User File(s), but we do not store, or otherwise access it, and it is not shared with anyone unless you yourself choose to share the User File with the location data.")
                    
                    SecondHeadlineText(icon: "bubble.left.and.bubble.right.fill", text:"Communications")
                    MainText(text: "Aside from User Files, Personal Information you provide to us may include the following:")
                    
                    Bulletpoint(text: "Your email address, which you may submit to us via the email address indicated on the App;")
                    
                    Bulletpoint(text: "Any other Personal Information that you voluntarily choose to provide to us, for instance when you communicate directly with us.")
                   
                    MainText(text: "If we ask you to provide any Personal Information not described above, the Personal Information that you are asked to provide and the reasons why you are asked to provide it will be made clear to you when asked to provide it, and it will be processed in accordance with this Privacy Notice.")
                }
                
                Group{
                    SecondHeadlineText(icon: "app.badge.fill", text:"Device Information")
                    MainText(text: "Data on device type, operating system, and the user experience is automatically collected when using our App and solely used to optimize and improve the usability of our App.")
                    
                    DotSeperator()
                    
                    HeadlineText(text: "Apple Analytics")
                    MainText(text: "We receive basic general usage information through Apple’s built in Analytics, as explained at: https://developer.apple.com/app-store-connect/analytics/.")
                    MainText(text: "Such information is aggregated and anonymized to protect individual users. We only receive and use this data in aggregate form, as a statistical measure, and not in a manner that would identify you personally, in order to improve our App.")
                    
                    DotSeperator()
                    
                    HeadlineText(text: "Information we do not collect")
                    MainText(text: "Playground does not have access to any content you create in the App, or to User Files that you import into the App, with the exception of the limited access at the time of capture of a User File and location data as explained above.")
                }
                
                Group{
                    MainText(text: "Likewise, we offer an in-App purchase that uses Apple’s built-in payment system to pay for a “watermark” to be removed. Apple handles the payment process, so we do not require or receive any payment information other than an anonymized token provided by Apple.")
                    
                    MainText(text: "Finally, Playground does not drop cookies.")
                    
                    DotSeperator()
                    
                    HeadlineText(text: "What we do with your information · Legal Bases")
                    MainText(text: "We do not sell any information that we collect to any third parties. We may process your Personal Information for different reasons, as further explained below. In addition, for users located in the European Economic Area (EEA), we must have a valid legal basis in order to process your Personal Information. The main legal bases under the European Union’s General Data Protection Regulation (GDPR) that justify the collection and use of your Personal Information are:")
                    Bulletpoint(text: "Performance of a contract – When your Personal Information is necessary to enter into or perform a contract with you.")
                    Bulletpoint(text: "Consent – When you have specifically and unambiguously consented to the use of your Personal Information via a consent form (online or offline).")
                    Bulletpoint(text: "Legitimate interests – When your Personal Information is processed to achieve a legitimate interest and the reasons for using it outweigh any prejudice to your data protection rights.")
                    Bulletpoint(text: "Legal obligation – When using your Personal Information is necessary to comply with legal obligations.")
                    Bulletpoint(text: "Legal claims – When Personal Information is necessary to defend, prosecute or make a claim.")
                }
                
                Group{
                    MainText(text: "Below are the general purposes and corresponding legal bases for which we may use your Personal Information:")
                    Bulletpoint(text: "Communicating with you about your use of the App, and/or in response to any inquiries you may make ➔ performance of a contract, legitimate interests, and in some cases, legal claims.")
                    Bulletpoint(text: "Complying with our legal, regulatory, or risk management obligations. We may use Personal Information to fulfill our legal obligations, for the prevention of fraud, to enforce our legal rights, to comply with any legal or regulatory reporting obligation, and/or to protect the rights of third parties ➔ legal obligation, legal claims, legitimate interests.")
                    Bulletpoint(text: "Recovering any payments due to us, including where necessary enforcing such recovery through the engagement of debt collection agencies or taking other legal action (including in connection with legal and court proceedings ➔ performance of a contract, legal claims.")
                    Bulletpoint(text: "Making changes to our business, for example, if we undergo a re-organization (i.e., we merge, combine or divest a part of our business). In this case, we may be required to disclose or transfer some or all of your Personal Information to a third party, as further described below ➔ legitimate interests.")
                    Bulletpoint(text: "All other information that we may use to improve our App or measure usage is provided to us in aggregated form and anonymous, and therefore does not require a legal basis.")
                    DotSeperator()
                    HeadlineText(text: "How we disclose information")
                    MainText(text: "We may disclose your Personal Information to the third parties indicated below (and for the following reasons).")
                    SecondHeadlineText(icon: "arrow.swap", text:"Third-Party Service Providers")
                }
                
                Group{
                    MainText(text: "The following categories of third parties may collect, process or receive your Personal Information in order to assist us in providing our App:")
                    Bulletpoint(text: "Google, as a service provider for our corporate emails;")
                    Bulletpoint(text: "Apple iOS, which hosts our App.")
                    SecondHeadlineText(icon: "shield.fill", text: "Legal Obligations & Security")
                    MainText(text: "We will disclose your Personal Information: (i) when we have a good faith belief it is required by law, such as pursuant to a subpoena, warrant or other judicial or administrative order (as further explained below); (ii) to protect the safety of any person; (iii) to protect the safety or security of our App or to prevent spam, abuse, or other malicious activity of actors on our App; or (iv) to protect our rights or property or the rights or property of those who use our App and/or services.")
                    MainText(text: "If we are required to disclose Personal Information by law, such as pursuant to a subpoena, warrant or other judicial or administrative order, our policy is to respond to requests that are properly issued by law enforcement.")
                    MainText(text: "Note that if we receive information that provides us with a good faith belief that there is an exigent emergency involving the danger of death or serious physical injury to a person, or the detection or prevention of a crime, we may provide information, including Personal Information, to law enforcement trying to prevent or mitigate the danger (if we have it), to be determined on a case-by-case basis.")
                    SecondHeadlineText(icon: "arrow.2.circlepath.circle.fill", text: "Legal Business Transfer")
                    MainText(text: "We may transfer your Personal Information to an affiliate, a successor entity upon a merger, consolidation or other corporate reorganization in which Playground participates, or to a purchaser or acquirer of all or substantially all of Playground’s business or assets, including a successor in bankruptcy.")
                    }
                    
                }

                Group{
                    Group{
                        DotSeperator()
                        HeadlineText(text: "Do Not Track (DNT)")
                        MainText(text: "DNT is a feature offered by some browsers which, when enabled, sends a signal to websites to request that your browsing is not tracked, such as by third party ad networks, social networks and analytic companies. We currently do not respond to DNT requests from visitors to our Sites.")
                        DotSeperator()
                        HeadlineText(text: "Security")
                        MainText(text: "The security of your Personal Information is important to us, and we strive to implement and maintain reasonable, commercially acceptable security procedures and practices appropriate to the nature of the information we store, in order to protect it from unauthorized access, destruction, use, modification, or disclosure.")
                        DotSeperator()
                        HeadlineText(text: "Changes to this privacy notice")
                        MainText(text: "We may amend this Privacy Notice from time to time. Use of information we collect now is subject to the Privacy Notice in effect at the time such information is used. If we make changes to the way we use Personal Information, we will update this page and provide you with notice of the updates. Users are bound by any changes to the Privacy Notice when using any part of the App or communicating with us directly after such changes have been first posted.")
                    }
                    
                    Group{
                        DotSeperator()
                        HeadlineText(text: "Children's Privacy")
                        MainText(text: "We do not knowingly collect Personal Information from minors. If you are a parent or guardian of a minor and believe he or she has disclosed Personal Information to us, please contact us at privacy@playground.ai.")
                        DotSeperator()
                        HeadlineText(text: "How we keep your information")
                        MainText(text: "Your Personal Information is processed for the period necessary to fulfill the purposes for which it is collected, to comply with legal and regulatory obligations and for the duration of any period necessary to establish, exercise or defend any legal rights.")
                        MainText(text: "In order to determine the most appropriate retention periods for your Personal Information, we consider the amount, nature and sensitivity of your Personal Information, the reasons for which we collect and process your Personal Information, best practices and applicable legal requirements.")
                        DotSeperator()
                        HeadlineText(text: "Additional Rights for users in the EEA")
                        MainText(text: "Although we collect very little Personal Information, it is important to know your rights. If the GDPR applies to you because you are in the European Economic Area, you have certain rights in relation to your Personal Information:")
                    }
                Group{
            
                    
                    
                    Bulletpoint(text: "The right to be informed – our obligation to inform you that we process your Personal Information (and that is what we are doing in this Privacy Notice);")
                    Bulletpoint(text: "The right of access – your right to request a copy of the Personal Information we hold about you (also known as a ‘data subject access request’);")
                      Bulletpoint(text: "The right to rectification – your right to request that we correct Personal Information about you if it is incomplete or inaccurate (though we generally recommend first make any changes in the App itself);")
                    Bulletpoint(text: "The right to erasure (also known as the ‘right to be forgotten’) – under certain circumstances, you may ask us to delete the Personal Information we have about you (unless there is an overriding legal reason we need to keep it);")
                    Bulletpoint(text: "The right to restrict processing – your right, under certain circumstances, to ask us to suspend our processing of your Personal Information;")
                    Bulletpoint(text: "The right to data portability – your right to ask us for a copy of your Personal Information in a common format (for example, a .csv file);")
                    Bulletpoint(text: "Rights in relation to automated decision-making and profiling – our obligation to be transparent about any profiling we do, or any automated decision-making.")
                }
                    
                Group{
                    MainText(text: "These rights are subject to certain rules regarding when you can exercise them, as well as our ability to verify your identity. We may need to request specific information from you to help us confirm your identity, and will need to ensure that this is sufficient for us to properly identify you. This is a security measure to ensure that Personal Information is not disclosed to any person who has no right to receive it. If we are unable to reasonably verify your identity, we may not be able to grant your request(s). If you are located in the European Economic Area and wish to exercise any of the rights set out above, please contact us at privacy@playground.ai.")
                    MainText(text: "You will not have to pay a fee to access your Personal Information (or to exercise any of the other rights) unless your request is clearly unfounded, repetitive or excessive. Alternatively, we may refuse to comply with your request under those circumstances or for other appropriate reasons that will be clearly communicated to you.")
                    MainText(text: "We will respond to all legitimate requests within one month. Occasionally, it may take us longer than a month if your request is particularly complex or you have made a number of requests. In this case, we will notify you and keep you updated as required by law.")
                    MainText(text: "Finally, you have the right to make a complaint at any time to the supervisory authority for data protection issues in your country of residence. However, we would appreciate the chance to address your concerns before you approach the supervisory authority, so please contact us first.")
                    MainText(text: "If you have any questions about this Privacy Notice, including any requests to exercise your legal rights, please contact us at privacy@playground.ai.")
                        
                }
                }
                
            }.padding(.horizontal, 32)
        }
        
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    
    static var previews: some View {
        PrivacyPolicyView(isPresented: .constant(false))
    }
}

struct MainText: View {
    var text: String
    
    var body: some View {
        VStack{
            Text(text)
                .font(Font.system(size: 16, weight: .regular, design: .serif))
                .lineSpacing(6)
                .foregroundColor(Color("text"))
                .padding(.vertical, 16)
        }
    }
}

struct DotSeperator: View {
    var body: some View {
        HStack(alignment: .center){
            Spacer()
            Circle()
                .foregroundColor(Color("lightblue").opacity(0.3))
                .frame(width: 6, height: 6, alignment: .center)
            Circle()
                .foregroundColor(Color("lightblue").opacity(0.3))
                .frame(width: 6, height: 6, alignment: .center)
            Circle()
                .foregroundColor(Color("lightblue").opacity(0.3))
                .frame(width: 6, height: 6, alignment: .center)
            Spacer()
        }
    }
}

struct HeadlineText: View {
    var text: String
    var body: some View {
        VStack {
            Text(text)
                .font(Font.system(size: 21, weight: .semibold))
                .foregroundColor(Color("text"))
                .padding(.top, 24)
                .padding(.vertical, 16)
        }
    }
}


struct SecondHeadlineText: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: icon)
                    .font(Font.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(Color("lightblue").opacity(0.6))
                Text(text)
                    .font(Font.system(size: 18, weight: .medium))
                    .foregroundColor(Color("lightblue"))
            }
            .padding(.top, 24)
            .padding(.vertical, 8)
        }
    }
}

struct Bulletpoint: View {
    var text: String
    
    var body: some View {
        HStack(alignment: .top){
          Circle()
            .frame(width: 4, height: 4, alignment: .top)
            .foregroundColor(Color("lightblue").opacity(0.3))
            //.padding(.trailing, 8)
            .padding(.top, 6)
  
            Text(text)
                .font(Font.system(size: 14, weight: .regular, design: .serif))
                
            
                .foregroundColor(Color("text").opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
        }
    }
}
