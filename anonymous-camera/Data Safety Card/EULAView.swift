//
//  EULAView.swift
//  SafetyCard
//
//  Created by Sarah Mautsch on 31.03.20.
//  Copyright © 2020 Sarah Mautsch. All rights reserved.
//

import SwiftUI

struct EULAView: View {
    @Binding var isPresented : Bool
    
    var body: some View {
        ScrollView{
            HStack {
                   Spacer()
                   ZStack {
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
                   .padding(.top, 20)
               }
            
            VStack(alignment: .leading){
           
                VStack(alignment: .leading){
            
                    HStack (alignment: .center) {
                        HStack (spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(Font.system(size: 30, weight: .semibold))
                            Text("Terms of Use")
                                .font(Font.system(size: 32, weight: .semibold))
                        }
                        .padding(.bottom, 8)
                    }
                    Text("Last Updated 31st of March 2020")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("lightblue"))
                }.padding(.bottom, 40)
                
                VStack (alignment: .leading){
                    Group{
                    HeadlineText(text: "Acceptance of Terms of Use")
                    MainText(text: "The following terms and conditions, together with any other notices or documents that they expressly incorporate by reference (collectively, these “Terms of Use”), are entered into by and between You and playground.ai, a Delaware corporation (“Playground”, “we” or “us”). The Terms of Use govern your access to and use of the Playground mobile application (“App”) and the Playground websites (collectively, “Website”) (the App and the Website, are collectively referred to hereinafter as the “Platform”), including any content, functionality and services offered on or through the Platform, whether as a guest or a registered user.")
                    MainTextHighlight(text: "Important: Please review the mutual agreement set forth below carefully, as it will requite you to resolve disputes with Playground on an individual basis (waiving your right to a class action) through final and binding arbitration. By entering this egreement, you expressly acknowledge that you have read and understand all of the terms of this mutual arbitration agreement and have taken the time to consider the consequences of this important decision. \n\nThese terms of use also contain releases, limitations on liability, and provisions on indemnity and assumption of risk, all of which may limit your legal rights and remedies. Please review them carefully.".uppercased())
                    MainText(text: "Please read the Terms of Use carefully before you start to use the App. By using the App or by clicking to accept or agree to the Terms of Use when this option is made available to you, you also accept and agree to be bound and abide by the Additional Terms (as explained below), which are incorporated herein by reference. If you do not want to agree to these Terms of Use or Additional Terms, you must not access or use the Platform.")
                    MainText(text: "By using the Platform, you represent and warrant that you are 18 or older and of legal age to form a binding contract with Playground and meet all of the foregoing eligibility requirements. If you do not meet all of these requirements, you must not access or use any part of the Platform.")
                    HeadlineText(text: "Additional Terms")
                    MainText(text: "Our Privacy Notice and other notices applicable to your use of the Platform are incorporated by reference into these Terms of Use (the “Additional Terms”), as updated from time to time.")
                    }
            Group{
                MainTextHighlightSubtle(text:"BY ACCESSING OR USING THE PLATFORM, YOU ACCEPT THESE ADDITIONAL TERMS.")
                MainText(text:" We will make Additional Terms available for you to read through the Platform. If you do not agree to abide by the Additional Terms, you automatically opt out of, and are prohibited from, using the Platform. If you violate the provisions of the Additional Terms, Playground may, in its sole discretion, suspend, discontinue, or change your account or any aspect of your access to or use of the Platform in whole or in part. By continuing to use the Platform, you agree to the Additional Terms and any future amendments and additions to the Additional Terms as published from time to time through the Platform. Please review the Additional Terms periodically to ensure you are up-to-date with any changes.")
                HeadlineText(text: "Changes to these Terms of Use")
                MainText(text: "We reserve the right to change or modify these Terms of Use at any time and in our sole discretion. If we make material changes to these Terms of Use, we will provide notice of such changes, such as by posting a notice on our Platform and/or updating the “Last Updated” date above. Your continued use of the Platform following the posting of changes or modifications will confirm your acceptance of such changes or modifications. If you do not agree to the amended Terms of Use, you must stop using our Platform.")
                HeadlineText(text: "Accessing the Platform / Account Security")
                MainText(text: "We reserve the right to withdraw or amend this Platform, and any service or material we provide on the Platform, in our sole discretion without notice. We will not be liable if for any reason all or any part of the Platform is unavailable at any time or for any period. From time to time, we may restrict access to some parts of the Platform, or the entire Platform, to users, including registered users.")
                MainText(text: "You are responsible for:")
                Bulletpoint(text: "Making all arrangements necessary for you to have access to the Platform; and")
                Bulletpoint(text: "Ensuring that all persons who access the Platform through your device are aware of these Terms of Use and comply with them.")
                MainText(text: "To access the Platform or some of the resources it offers, you may be asked by Apple to provide certain details or other information. It is a condition of your use of the Platform that all the information you provide is correct, current and complete. You agree that all personal information you provide in connection with your use of the App or otherwise, including but not limited to through any communications directly to us, is governed by our Privacy Notice, which is part of our Additional Terms incorporated herein by reference as explained above, and you consent to all actions we take with respect to your personal information consistent with our Privacy Notice.")
            }
            Group{
                MainTextHighlightSubtle(text: "You agree that you have the right to submit any personal information to Playground and that such personal information is accurate.".uppercased())
                HeadlineText(text: "Intellectual Property Rights")
                MainText(text: "The Platform and its entire contents, features and functionality (including but not limited to all information, software, text, displays, images, video and audio, and the design, selection and arrangement thereof), are owned by Playground, its licensors or other providers of such material and are protected by United States and international copyright, trademark, patent, trade secret and other intellectual property or proprietary rights laws.")
                MainText(text: "These Terms of Use permit you to use the Platform for your personal, non-commercial use only. You must not reproduce, distribute, modify, create derivative works of, publicly display, publicly perform, republish, download, store or transmit any of the material on our Platform, except as follows:")
                Bulletpoint(text: "You may print or download one copy of a reasonable number of pages of the Website for your own personal, non-commercial use and not for further reproduction, publication or distribution.")
                Bulletpoint(text: "You may download a single copy of the App to your mobile device solely for your own personal, non-commercial use.")
                MainText(text: "You must not:")
                Bulletpoint(text: "Modify copies of any materials from the Platform.")
                Bulletpoint(text: "Use any illustrations, photographs, video or audio sequences or any graphics separately from the accompanying text.")
                Bulletpoint(text: "Delete or alter any copyright, trademark or other proprietary rights notices from copies of materials from the Platform.")
            }
            Group{
                MainText(text: "You must not access or use for any commercial purposes any part of the Platform or any services or materials available through the Platform.")
                MainText(text: "If you wish to make any use of material on the Platform other than that set out in this section, please address your request to: support@playground.ai.")
                MainText(text: "If you print, copy, modify, download or otherwise use or provide any other person with access to any part of the Platform in breach of the Terms of Use, your right to use the Platform will cease immediately and you must, at our option, return or destroy any copies of the materials you have made. No right, title or interest in or to the Platform or any content on the Platform is transferred to you, and all rights not expressly granted are reserved by Playground. Any use of the Platform not expressly permitted by these Terms of Use is a breach of these Terms of Use and may violate copyright, trademark and other laws.")
                HeadlineText(text: "Trademarks")
                MainText(text: "Playground’s name, logo and all related names, logos, product and service names, designs and slogans are trademarks of Playground or its affiliates or licensors. You must not use such marks without the prior written permission of Playground. All other names, logos, product and service names, designs and slogans on this Platform are the trademarks of their respective owners.")
                HeadlineText(text: "Prohibited Uses")
                MainText(text: "You may use the Platform only for lawful purposes and in accordance with these Terms of Use. You agree not to use the Platform:")
                Bulletpoint(text: "In any way that violates any applicable federal, state, local or international law or regulation (including, without limitation, any laws regarding the export of data or software to and from the US or other countries).")
                Bulletpoint(text: "For the purpose of exploiting, harming or attempting to exploit or harm minors in any way by exposing them to inappropriate content, asking for personal information or otherwise.")
                Bulletpoint(text: "To transmit, or procure the sending of, any advertising or promotional material without our prior written consent, including any “junk mail”, “chain letter” or “spam” or any other similar solicitation.")
            }
            Group{
                Bulletpoint(text: "To impersonate or attempt to impersonate Playground, a Playground employee, another user or any other person or entity, including, without limitation, by using e-mail addresses, telephone numbers, or screen names associated with any of the foregoing, or otherwise submitting false information.")
                Bulletpoint(text: "To engage in any other conduct that restricts or inhibits anyone's use or enjoyment of the Platform, or which, as determined by us, may harm Playground or users of the Platform or expose them to liability.")
                MainText(text: "Additionally, you agree not to:")
                Bulletpoint(text: "Use the Platform in any manner that could disable, overburden, damage, or impair the  Platform or interfere with any other party's use of the Platform, including their ability to engage in real time activities through the Platform.")
                Bulletpoint(text: "Use any robot, spider or other automatic device, process or means to access the Platform for any purpose, including monitoring or copying any of the material on the Platform.")
                Bulletpoint(text: "Use any manual process to monitor or copy any of the material on the Platform or for any other unauthorized purpose without our prior written consent.")
                Bulletpoint(text: "Copy, duplicate, alter, reverse engineer, download, publish, modify, create derivative works, publicly display or otherwise distribute any content or software contained in the Platform.")
                Bulletpoint(text: "Use any device, software or routine that interferes with the proper working of the Platform.")
                Bulletpoint(text: "Introduce any viruses, trojan horses, worms, logic bombs or other material which is malicious or technologically harmful.")
            }
            Group{
                Bulletpoint(text: "Attempt to gain unauthorized access to, interfere with, damage or disrupt any parts of the Platform, the server on which the Platform is stored, or any server, computer or database connected to the Platform.")
                Bulletpoint(text: "Attack the Platform via a denial-of-service attack or a distributed denial-of-service attack.")
                Bulletpoint(text: "Attempt to gain unauthorized access to any personal information that may be contained on the Platform, the server on which the Platform is stored, or any server, computer, database or information system connected to the Platform.")
                MainText(text: "Otherwise attempt to interfere with the proper working of the Platform.")
                HeadlineText(text: "App-Specific terms and license")
                MainText(text: "Limited License")
                MainText(text: "Notwithstanding anything to the contrary herein and subject to your compliance with these Terms of Use, Playground grants you a limited non-exclusive, non-transferable license to download and install a copy of the App on a single mobile device or computer that you own or control and run such copy of the App solely for your own personal use. Furthermore, with respect to the App you will only use the App (i) on an Apple-branded product that runs the iOS (Apple’s proprietary operating system); and (ii) as permitted by applicable “Usage Rules” set forth in the Apple App Store Terms of Use. Playground reserves all rights in the App not expressly granted to you by these Terms of Use.")
                MainText(text: "IOS Users")
                MainText(text: "With regard to your use of the App, you acknowledge and agree that (i) these Terms of Use are an agreement between you and Playground only, and not Apple, and (ii) Playground, not Apple, is solely responsible for the App and content thereof. Your use of the App must comply with the App Store Terms of Use. You acknowledge that Apple has no obligation whatsoever to furnish any maintenance and support services with respect to the App. In the event of any failure of the App to conform to any applicable warranty, you may notify Apple, and Apple will refund the purchase price for the App to you and to the maximum extent permitted by applicable law, Apple will have no other warranty obligation whatsoever with respect to the App. As between Playground and Apple, any other claims, losses, liabilities, damages, costs or expenses attributable to any failure to conform to any warranty will be the sole responsibility of Playground, subject to the these Terms of Use. You and Playground acknowledge that, as between Playground and Apple, Apple is not responsible for addressing any claims you have or any claims of any third party relating to the App or your possession and use of the App, including, but not limited to: (i) product liability claims; (ii) any claim that the App fails to conform to any applicable legal or regulatory requirement; and (iii) claims arising under consumer protection or similar legislation. You and Playground acknowledge that, in the event of any third-party claim that the App or your possession and use of that App infringes that third party’s intellectual property rights, as between Playground and Apple, Playground, not Apple, will be solely responsible for the investigation, defense, settlement and discharge of any such intellectual property infringement claim to the extent required by, and subject to, these Terms of Use. You and Playground acknowledge and agree that Apple, and Apple’s subsidiaries, are third-party beneficiaries of these Terms of Use as related to your license of the App, and that, upon your acceptance of the Terms of Use and conditions of these Terms of Use, Apple will have the right (and will be deemed to have accepted the right) to enforce these Terms of Use as related to your license of the App against you as a third-party beneficiary thereof.")
                HeadlineText(text: "Changes to the Platform")
            }
            Group{
                MainText(text: "We may update the content on this Platform from time to time, at our sole discretion, but its content may not necessarily or always be complete or up-to-date. Any of the material on the Platform may be out-of-date at any given time, and we are under no obligation to update such material, including without limitation the functionality of the App. We may choose to permanently remove the App at any time.")
                HeadlineText(text: "User is Responsible for all Uploaded Files")
                MainText(text: "The App allows users to take photographs and videos or record audio clip (each a “User File”) with the App on their mobile devices. Users are solely responsible for all content of any User Files that they upload to their mobile device(s) and/or use in connection with the App.")
                MainText(text: "You agree that you are responsible for obtaining any licenses, releases, waivers in connection with your use, including modification, disclosure or other action, of the User Files. This includes, without limitation, obtaining releases from individuals whose photo or likeness may be included in a User File or a license from a company whose intellectual property is included in the User Files, where applicable.")
                MainTextHighlightSubtle(text: "YOU FURTHER AGREE THAT YOU ARE SOLELY RESPONSIBLE FOR ALL USER FILES THAT ARE USED WITH OR UPLOADED INTO THE APP, INCLUDING ANY USER FILES THAT YOU SHARE OR SELL, AND THAT PLAYGROUND SHALL HAVE NO LIABILITY TO ANY THIRD PARTY IN CONNECTION WITH YOUR USE OF USER FILES AND/OR ANY CONTENT CONTAINED THEREIN.".uppercased())
                HeadlineText(text: "Disclaimer of Warranties")
                MainText(text: "You understand that we cannot and do not guarantee or warrant that files or software available for downloading from the internet or the Platform will be free of viruses or other destructive code. You are responsible for implementing sufficient procedures and checkpoints to satisfy your particular requirements for anti-virus protection and accuracy of data input and output, and for maintaining a means external to our site for any reconstruction of any lost data.")
                MainTextHighlight(text: "WE WILL NOT BE LIABLE FOR ANY LOSS OR DAMAGE CAUSED BY A DISTRIBUTED DENIAL-OF-SERVICE ATTACK, VIRUSES OR OTHER TECHNOLOGICALLY HARMFUL MATERIAL THAT MAY INFECT YOUR COMPUTER EQUIPMENT, COMPUTER PROGRAMS, DATA OR OTHER PROPRIETARY MATERIAL DUE TO YOUR USE OF THE PLATFORM OR ANY SERVICES OR ITEMS OBTAINED THROUGH THE PLATFORM OR TO YOUR DOWNLOADING OF ANY MATERIAL POSTED ON IT, OR ON ANY WEBSITE LINKED TO IT.\n\nYOUR USE OF THE PLATFORM, ITS CONTENT AND ANY SERVICES OR ITEMS OBTAINED THROUGH THE PLATFORM IS AT YOUR OWN RISK. THE PLATFORM, ITS CONTENT AND ANY SERVICES OR ITEMS OBTAINED THROUGH THE PLATFORM ARE PROVIDED ON AN “AS IS” AND “AS AVAILABLE” BASIS, WITHOUT ANY WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. NEITHER PLAYGROUND NOR ANY PERSON ASSOCIATED WITH PLAYGROUND MAKES ANY WARRANTY OR REPRESENTATION WITH RESPECT TO THE COMPLETENESS, SECURITY, RELIABILITY, QUALITY, ACCURACY OR AVAILABILITY OF THE PLATFORM. WITHOUT LIMITING THE FOREGOING, NEITHER PLAYGROUND NOR ANYONE ASSOCIATED WITH PLAYGROUND REPRESENTS OR WARRANTS THAT THE PLATFORM, ITS CONTENT OR ANY SERVICES OR ITEMS OBTAINED THROUGH THE PLATFORM WILL BE ACCURATE, RELIABLE, ERROR-FREE OR UNINTERRUPTED, THAT DEFECTS WILL BE CORRECTED, THAT OUR SITE OR THE SERVER THAT MAKES IT AVAILABLE ARE FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS OR THAT THE PLATFORM OR ANY SERVICES OR ITEMS OBTAINED THROUGH THE PLATFORM WILL OTHERWISE MEET YOUR NEEDS OR EXPECTATIONS.\n\nPLAYGROUND HEREBY DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, STATUTORY OR OTHERWISE, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT AND FITNESS FOR PARTICULAR PURPOSE.\n\nTHE FOREGOING DOES NOT AFFECT ANY WARRANTIES WHICH CANNOT BE EXCLUDED OR LIMITED UNDER APPLICABLE LAW.".uppercased())
                HeadlineText(text: "Limitation of liability")
                MainTextHighlight(text: "IN NO EVENT WILL PLAYGROUND, ITS AFFILIATES OR THEIR LICENSORS, SERVICE PROVIDERS, EMPLOYEES, AGENTS, OFFICERS OR DIRECTORS BE LIABLE, UNDER ANY LEGAL THEORY, ARISING OUT OF OR IN CONNECTION WITH YOUR USE, OR INABILITY TO USE, THE PLATFORM, ANY WEBSITES LINKED TO IT, ANY CONTENT ON THE PLATFORM OR SUCH OTHER WEBSITES OR ANY SERVICES OR ITEMS OBTAINED THROUGH THE PLATFORM OR SUCH OTHER WEBSITES, FOR ANY INDIRECT, SPECIAL, INCIDENTAL, CONSEQUENTIAL OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO, PERSONAL INJURY, PAIN AND SUFFERING, EMOTIONAL DISTRESS, LOSS OF REVENUE, LOSS OF PROFITS, LOSS OF BUSINESS OR ANTICIPATED SAVINGS, LOSS OF USE, LOSS OF GOODWILL, LOSS OF DATA, AND WHETHER CAUSED BY TORT (INCLUDING NEGLIGENCE), BREACH OF CONTRACT OR OTHERWISE, EVEN IF FORESEEABLE AND IN NO EVENT WILL PLAYGROUND, ITS AFFILIATES OR THEIR LICENSORS, SERVICE PROVIDERS, EMPLOYEES, AGENTS, OFFICERS OR DIRECTORS BE LIABLE FOR MORE THAN ONE HUNDRED DOLLARS IN THE AGGREGATE.\n\nTHE FOREGOING DOES NOT AFFECT ANY LIABILITY WHICH CANNOT BE EXCLUDED OR LIMITED UNDER APPLICABLE LAW.".uppercased())
            }
            Group{
                HeadlineText(text: "Indemnification")
                MainText(text: "You agree to defend, indemnify and hold harmless Playground, its affiliates, licensors and service providers, and its and their respective officers, directors, employees, contractors, agents, licensors, suppliers, successors and assigns from and against any claims, liabilities, damages, judgments, awards, losses, costs, expenses or fees (including reasonable attorneys' fees), including third-party claims, arising out of or relating to your violation of these Terms of Use or your use of the Platform, including, but not limited to, your use or disclosure of User Files.")
                HeadlineText(text: "Binding Arbitration / Class Action Waiver")
                NumberedBulletpoint(title: "Dispute Resolution", text: "Certain portions of this Section are deemed to be a “written agreement to arbitrate” pursuant to the Federal Arbitration Act (“FAA”). You and Playground expressly agree and intend that this Section satisfies the “writing” requirement of the Federal Arbitration Act. This Section can only be amended by mutual agreement. For purposes of this Section, “Claims” means collectively, and without limitation, any and all claims, injuries, demands, liabilities, disputes, causes of action (including statutory, contract, negligence, or other tort theories), proceedings, obligations, debts, liens, fines, charges, penalties, contracts, promises, costs, expenses (including attorneys’ fees, whether incurred pre-litigation, pre-trial, at trial, on appeal, or otherwise), damages of any kind whatsoever (including consequential, compensatory, or punitive damages), or losses (whether known, unknown, asserted, non-asserted, fixed, conditional, or contingent) that arise from or relate to (i) the Platform, including any and all contents, materials and software related thereto, and/or (ii) your use of the Platform and of your User Files.", symbol: "1.circle.fill")
                NumberedBulletpoint(title: "Informal Resolution of Disputes and Excluded Disputes", text: "If any Claim arises out of or relates to the Platform or these Terms of Use, other than as may be provided herein, then you and Playground agree to send notice to the other providing a reasonable description of the Claim, along with a proposed resolution of it. Playground notice to you will be sent to you based on the most recent contact information that you provide Playground. If no such information exists or if such information is not current, Playground has no obligation under this Section. For a period of sixty (60) days from the date of receipt of notice from the other party, you and Playground will engage in a dialog to attempt to resolve the Claim, though nothing will require either you or Playground to resolve the Claim on terms with respect to which you and Playground, in each of our sole discretion, are not comfortable.", symbol: "2.circle.fill")
                NumberedBulletpoint(title: "Binding Arbitration", text: "If you and Playground cannot resolve a Claim, within sixty (60) days of the receipt of the notice, then you agree that that any such Claim and all other disputes arising out of or relating to the interpretation, applicability, enforceability or formation of these Terms of Use, including, but not limited to any claim that all or any part of these Terms of Use are void or voidable, or whether a claim is subject to arbitration relating to Your use of the Platform, will be resolved by binding arbitration, rather than in court. The FAA, not state law, shall govern the arbitrability of such disputes, including the class action waiver below. However, you and Playground agree that California state law or United States federal law shall apply to, and govern, as appropriate, any and all Claims or disputes arising between you and Playground regarding these Terms of Use and the Platform, whether arising or stated in contract, statute, common law, or any other legal theory, without regard to choice of law principles. There is no judge or jury in arbitration, and court review of an arbitration award is limited. However, an arbitrator must follow the terms of these Terms of Use as a court would. ", symbol: "3.circle.fill")
                MainTextHighlight(text: "THIS SECTION, INCLUDING THE PROVISIONS ON BINDING ARBITRATION AND CLASS ACTION WAIVER, SHALL SURVIVE ANY TERMINATION OF YOUR ACCOUNT OR THE PLATFORM.")
                NumberedBulletpoint(title: "Initiating Arbitration", text: "To begin an arbitration proceeding, you must send a letter requesting arbitration and describing your claim to Playground at PO Box 3878, Barrington, Illinois 60011, USA. The arbitration will be conducted by JAMS in accordance with the JAMS Streamlined Arbitration Procedure Rules in effect at the time the arbitration is initiated, excluding any rules or procedures governing or permitting class actions. Payment of all filing, administration and arbitrator fees will be governed by JAMS's rules. The arbitration shall take place in San Jose, California or at such other venue (and pursuant to such procedures) as is mutually agreed upon. You can obtain JAMS procedures, rules, and fee information as follows: JAMS: 800.352.5267 and http://www.jamsadr.com. ", symbol: "a.circle.fill")
                NumberedBulletpoint(title: "Fees", text: "You and Playground will pay the administrative and arbitrator’s fees and other costs in accordance with the applicable arbitration rules; but if applicable arbitration rules or laws require Playground to pay a greater portion or all of such fees and costs in order for this Section to be enforceable, then Playground will have the right to elect to pay the fees and costs and proceed to arbitration. Arbitration rules may permit You to recover attorneys’ fees. Playground will not seek to recover attorneys’ fees and costs in arbitration unless the arbitrator determines the claims are frivolous.", symbol: "b.circle.fill")
                NumberedBulletpoint(title: "Class Action Waiver", text: "YOU AND PLAYGROUND EACH AGREE THAT ANY DISPUTE RESOLUTION PROCEEDING WILL BE CONDUCTED ONLY ON AN INDIVIDUAL BASIS AND NOT IN A CLASS, CONSOLIDATED OR REPRESENTATIVE ACTION. You and Playground each agree that such proceeding shall take solely by means of judicial reference pursuant to California Code of Civil Procedure section 638.", symbol: "c.circle.fill")
            }
            Group{
                NumberedBulletpoint(title: "Exclusions; Venue", text: "Notwithstanding the agreement to resolve all disputes through arbitration, you or Playground may bring suit in court to enjoin infringement or other misuse of intellectual property rights (including patents, copyrights, trademarks, trade secrets, and moral rights, but not including privacy rights). You or Playground may also seek relief in small claims court for Claims within the scope of that court’s jurisdiction. In the event that the arbitration provisions above are found not to apply to you or to a particular Claim, either as a result of your decision to opt-out of the arbitration provisions or as a result of a decision by the arbitrator or a court order, you agree that the venue for any such Claim or dispute is exclusively that of a state or federal court located in Santa Clara County, California. You and Playground agree to submit to the personal jurisdiction of the courts located within Santa Clara County, California for the purpose of litigating all such Claims or any other disputes arising out of or relating to the interpretation, applicability, enforceability or formation of these Terms of Use or Your use of the Platform in the event that the arbitration provisions are found not to apply. In such a case, should Playground prevail in litigation against you to enforce its rights under the Terms of Use, Playground shall be entitled to its costs, expenses, and reasonable attorneys’ fees (whether incurred at or in preparation for trial, appeal or otherwise) incurred in resolving or settling the dispute, in addition to all other damages or awards to which Playground may be entitled. ", symbol: "d.circle.fill")
                NumberedBulletpoint(title: "Limited Time to File Claims", text: "TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, IF YOU OR PLAYGROUND WANT TO ASSERT A DISPUTE AGAINST THE OTHER, THEN YOU OR PLAYGROUND MUST COMMENCE IT (BY DELIVERY OF WRITTEN NOTICE AS SET FORTH HEREIN) WITHIN ONE (1) YEAR AFTER THE DISPUTE ARISES OR IT WILL BE FOREVER BARRED. “Commencing” means, as applicable: (i) by delivery of written notice as set forth herein; (ii) filing for arbitration with JAMS as set forth herein; or (iii) filing an action in state or federal court. This provision will not apply to any legal action taken by Playground to seek an injunction or other equitable relief in connection with any losses (or potential losses) relating to the Platform, intellectual property rights of Playground, and/or Playground’ of the Platform.", symbol: "e.circle.fill")
                NumberedBulletpoint(title: "Your Right to Opt-Out.", text: "You have the right to opt-out and not be bound by the arbitration and class action waiver provisions set forth above by sending written notice of your decision to opt-out to: support@playground.ai with the subject line “PLAYGROUND ARBITRATION AND CLASS ACTION WAIVER OPT-OUT.” The notice must be sent within thirty (30) days of your first use of the Platform, otherwise you shall be bound to arbitrate any disputes in accordance with the terms of these Terms of Use providing for binding arbitration. If you opt-out of these arbitration provisions, Playground also will not be bound by them.", symbol: "f.circle.fill")
                HeadlineText(text: "Term and Termination")
                MainText(text: "These Terms of Use will continue to apply to you until terminated by either you or Playground. PLAYGROUND MAY TERMINATE THESE TERMS OF USE OR SUSPEND YOUR ACCESS TO THE PLATFORM AT ANY TIME, INCLUDING IN THE EVENT OF YOUR ACTUAL OR SUSPECTED UNAUTHORIZED USE OF THE PLATFORM OR NON-COMPLIANCE WITH THE TERMS OF USE, OR IF WE WITHDRAW THE PLATFORM OR ANY CONTENT CONTAINED THEREIN. If you or Playground terminates these Terms of Use, or if we suspend your access to the Platform, you agree that Playground shall have no liability or responsibility to you, and that Playground will not refund any amounts that you have already paid via the Apple Store, to the fullest extent permitted under applicable law. You may terminate these Terms of Use at any time. To learn how to terminate your Playground account, please contact us at support@playground.ai.This section will be enforced to the fullest extent permissible by applicable law.\n\nAny sections of these Terms of Use, including but not limited to ‘Indemnification’, ‘Intellectual Property’, ‘Disclaimers’, ‘Limitation of Liability’, ‘Binding Arbitration; Class Action Waiver’,  that either explicitly or by their nature, must remain in effect even after termination of these Terms of Use, shall survive termination.")
                HeadlineText(text: "Waiver and Severability")
                MainText(text: "No waiver of by Playground of any term or condition set forth in these Terms of Use shall be deemed a further or continuing waiver of such term or condition or a waiver of any other term or condition, and any failure of Playground to assert a right or provision under these Terms of Use shall not constitute a waiver of such right or provision.\n\nIf any provision of these Terms of Use is held by a court, arbitration body or other tribunal of competent jurisdiction to be invalid, illegal or unenforceable for any reason, such provision shall be eliminated or limited to the minimum extent such that the remaining provisions of the Terms of Use will continue in full force and effect. ")
                HeadlineText(text: "Entire Agreement")
                MainText(text: "The Terms of Use and our Privacy Notice constitute the sole and entire agreement between you and Playground with respect to the Platform.")
                HeadlineText(text: "Questions or Comments")
            }
            }
            VStack (alignment: .leading){
                Group{
                    MainText(text:"The contracting entity is Playground [CORPORATE NAME] located at:")
                    MainText(text: "PO Box 3878, Barrington, Illinois 60011, USA")
                    MainText(text: "All other feedback, comments, requests for technical support and other communications relating to the Platform should be directed to: support@playground.ai.")
                    MainText(text: "Thank you for reading our Terms of Use.")
                }
            }
          }.padding(.horizontal, 32)
        }
    }
}


struct EULAView_Previews: PreviewProvider {
    static var previews: some View {
        EULAView(isPresented: .constant(false))
    }
}

struct MainTextHighlight: View {
    var text: String
    
    var body: some View {
        VStack{
            Text(text)
                .font(Font.system(size: 14, weight: .semibold, design: .rounded))
                .lineSpacing(6)
                .foregroundColor(Color("text"))
                .padding(.vertical, 16)
        }
    }
}

struct MainTextHighlightSubtle: View {
    var text: String
    
    var body: some View {
        VStack{
            Text(text)
                .font(Font.system(size: 14, weight: .regular, design: .rounded))
                .lineSpacing(6)
                .foregroundColor(Color("text"))
                .padding(.vertical, 16)
        }
    }
}

struct NumberedBulletpoint: View {
    var title: String
    var text: String
    var symbol: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top){
                Image(systemName: symbol)
                .foregroundColor(Color("lightblue").opacity(0.4))
                .padding(.top, 2)

      
                Text(title)
                    .font(Font.system(size: 14, weight: .bold, design: .default))
                    .foregroundColor(Color("text").opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(6)
            }
            .padding(.bottom, 4)
            Text(text)
                .font(Font.system(size: 14, weight: .regular, design: .serif))
                .foregroundColor(Color("text").opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6)
        }
        //.padding(.top, 6)
        .padding(.bottom,12)
    }
}

