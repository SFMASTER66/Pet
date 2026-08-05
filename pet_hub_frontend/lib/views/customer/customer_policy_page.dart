import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerPolicyPage extends StatelessWidget {
  final MerchantConfig config;

  const CustomerPolicyPage({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: config,
      activeTab: CustomerTab.policy,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isDesktop = constraints.maxWidth > 900;

          // Dynamic paddings and font size based on screen width
          final horizontalPadding = isMobile
              ? 16.0
              : isDesktop
                  ? 48.0
                  : 32.0;
          final titleFontSize = isMobile ? 24.0 : 32.0;

          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "PAWPARAZZI PET GROOMING POLICY",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4C5844),
                        letterSpacing: 1.1,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "At Pawparazzi Pet, we strive to provide exceptional dog grooming services while ensuring the safety, well-being, and comfort of all the dogs in our care. To maintain a positive and safe environment, we have established the following dog grooming policy.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Please read before any service of your pet's appointment today. You agree to the following salon policies, procedures, terms, and conditions by booking and attending your appointment.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Policy Items Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFCE8), // Light yellow background
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Policy Section 1
                          _buildPolicySection(
                            title: "1. Fully vaccines",
                            content:
                                "All dogs must be up to date on vaccinations. If your dog is unwell, has a contagious condition, or is exhibiting signs of illness, we may refuse grooming services to protect the health of other dogs in our facility. For puppies, we required they done Booster (the third vaccination) and owner must provide vaccination certification.",
                          ),
                          const SizedBox(height: 24),

                          // Policy Section 2
                          _buildPolicySection(
                            title: "2. Senior dogs (first visit aged 12+)",
                            content:
                                "For dogs 12 years and older attending our salon for the first time, a veterinary report covering the past 12 months is required. This helps us assess safety and comfort; we may respectfully decline service if the report indicates significant risk.",
                          ),
                          const SizedBox(height: 24),

                          // Policy Section 3
                          _buildPolicySection(
                            title: "3. Aged Dogs/ special medical conditions",
                            content:
                                "At Pawparazzi Pet, the health and well-being of your pet is our top priority. However, it is important to understand that the grooming process can sometimes be stressful, particularly for aged pets or those with special medical conditions. This stress may potentially exacerbate latent, unknown, or inactive health issues, leading to complications such as illness, seizures, or, in rare cases, the death of the pet.\n\n"
                                "To ensure the safety and comfort of your pet, we require that you disclose any known health conditions your pet may have before grooming. This includes, but is not limited to, heart disease, epilepsy, cancer, arthritis, or any other medical conditions that could affect your pet during grooming. Failure to disclose such conditions may result in unforeseen accidents or health complications, for which Pawparazzi Pet will not be held liable.\n\n"
                                "Additionally, we reserve the right to refuse service to pets whose health conditions may make grooming unsafe or overly stressful. Our decision will be based on our professional assessment and is made with your pet's best interests in mind.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 4
                          _buildPolicySection(
                            title: "4. Emergency",
                            content:
                                "If your dog becomes unwell while in our care and we are unable to reach you, we will take your dog to our partnered veterinary clinic. You will be responsible for any veterinary costs incurred unless it has been explicitly agreed in advance that Pawparazzi Pet will cover the expenses. If any unforeseen health issues or accidental injuries occur while your dog is in the care of Pawparazzi Pet — such as sudden illness, seizures, age-related conditions, or heart problems — we will take immediate emergency action. However, we cannot be held legally responsible for the outcome of such incidents.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 5
                          _buildPolicySection(
                            title: "5. Heavily soiled or neglected coats",
                            content:
                                "If a dog arrives in a heavily soiled, matted, or unkempt condition due to a lack of regular bathing or grooming, it may require extra time, effort, and multiple washes to ensure the dog is clean and comfortable. In such cases, an additional grooming fee will be applied based on the condition of the coat and the time required. Extra charge starts from \$30, depends on size of dogs. We will always inform you in advance whenever possible.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 6
                          _buildPolicySection(
                            title: "6. Deposit",
                            content:
                                "We do not accept verbal appointments. All appointments — whether made online or by phone — require a \$30 deposit to confirm your booking. If you book online, you will be asked for deposit to complete your booking. If you book via phone call/ message/ email, you may pay the deposit in one of the following ways:\n"
                                "- In-store payment\n"
                                "- Bank transfer (please send a screenshot as confirmation)\n"
                                "- Credit/debit card (we can take card details over the phone if needed)\n\n"
                                "Unfortunately, due to a high number of no-shows in the past, we have been forced to implement this deposit policy to protect our time and resources. We highly recommend that new clients book through our website, as it is the most convenient and efficient method.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 7
                          _buildPolicySection(
                            title: "7. Cancellation/ No-show",
                            content:
                                "You’ll receive a confirmation email after booking. If you’d like a reminder, let us know—we can send one via call or SMS. Pawparazzi Pet is by appointment only. Being over 30 minutes late, not showing up, or cancelling less than 24 hours in advance will result in forfeiture of your deposit. Due to frequent no-shows and last-minute cancellations, these policies are strictly enforced to respect our team’s time and other clients. For full details, please review our cancellation/reschedule policy on the homepage.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 8
                          _buildPolicySection(
                            title: "8. Aggressive or Dangerous Dogs",
                            content:
                                "Owners must inform Pawparazzi Pet if their dog has ever shown aggression or has bitten people, other animals, or reacts negatively to grooming. Muzzles may be used when needed for safety. We reserve the right to refuse or stop grooming at any time if a dog is aggressive, and an Aggressive Dog Fee may apply in addition to the regular grooming cost, even if a quote was already given.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 9
                          _buildPolicySection(
                            title: "9. Matted Dogs",
                            content:
                                "Dogs with matted coats require extra grooming attention. Mats can tighten over time, causing skin damage, irritation, and potential health issues such as infections. Removing mats can be difficult and may involve shaving, which carries the risk of nicks, cuts, or abrasions. Heavy matting can also trap moisture, leading to skin issues.\n\n"
                                "Please note that there is an additional charge (start from \$30) for matted dogs. We advise regular grooming to prevent matting. If veterinary treatment is needed due to matting-related issues, the cost will not be covered by Pawparazzi Pet.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 10
                          _buildPolicySection(
                            title: "10. Double Coat Shave Down",
                            content:
                                "I understand and agree that I am leaving my double-coated dog with Pawparazzi Pet to be shaved. I have also been informed of the following:\n"
                                "• We cannot guarantee that the dog's coat will grow back after shaving\n"
                                "• Depending on how close the coat is clipped, your dog might require sunscreen to protect the dog's skin from being burned\n"
                                "• Shaving may cause irritation and/or rash\n"
                                "• Shaving the coat does not necessarily make the dog feel cooler, as the double coat acts as insulation in warm and cool weather\n"
                                "• Shaving does not reduce shedding; it only makes the shedding coat shorter\n"
                                "• Clipping down a double-coated dog can look uneven or choppy depending on your dog's coat type and the length requested\n"
                                "Our groomers will do their best to make the haircut look the best possible. I am aware and understand the above and agree to have my dog shaved.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 11
                          _buildPolicySection(
                            title: "11. Dog Grooming Style",
                            content:
                                "We will do our best to accommodate any special requests, but please understand that certain limitations may apply based on your dog's breed, coat condition, temperament, or specific grooming needs. If you have preference, please provide specific instructions for your desired grooming style. Pictures are encouraged. Some breeds have standard grooming styles. Please let us know if you have a preference. We reserve the right to refuse any requests that may jeopardies the safety or well-being of the dog.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 12
                          _buildPolicySection(
                            title: "12. Biting",
                            content:
                                "We reserve the right to use muzzles or other appropriate tools to ensure the safety of our staff during grooming sessions. We may refuse or discontinue grooming services to over aggressive dogs to ensure the safety of our staff and other dogs. In case of serious circumstances, we reserve the right to refuse or terminate the service, and the owner is responsible for bearing the injury expenses of the store's employees.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 13
                          _buildPolicySection(
                            title: "13. Flea Control",
                            content:
                                "If we discover that your dog has fleas prior to providing any services, we reserve the right to refuse service to protect the well-being of other animals in our facility.\n\n"
                                "If fleas are discovered during the bathing process, we are required to use a flea shampoo, which will incur an additional charge. Additionally, there will be a \$100 fee for the cleaning and disinfection of our grooming area to prevent the spread of fleas to other dogs.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 14
                          _buildPolicySection(
                            title: "14. Late Pick-Ups",
                            content:
                                "We do not have boarding facilities. If your dog is not picked up within 1 hour of notice, an additional \$20.00 per hour cage charge may also apply, if after trading hour, surcharge from \$50.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 15
                          _buildPolicySection(
                            title: "15. Photo on Social Media",
                            content:
                                "Photos may occasionally be taken during the grooming process for documentation purposes and, at times, shared on our social media platforms. If you prefer that your pet's photos, not be used online or in any promotional materials, please let us know in advance — we will fully respect your wishes and exclude your pet from any media use.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 16
                          _buildPolicySection(
                            title: "16. Handling Fee",
                            content:
                                "Handling fee may apply for Difficult/Aggressive/Overly Active Dogs from \$30.",
                          ),

                          const SizedBox(height: 24),

                          // Policy Section 17
                          _buildPolicySection(
                            title: "17. Nails trim",
                            content:
                                "For nail trim–only appointments, we cannot guarantee a complete trim, as it depends entirely on your dog’s level of cooperation. If a dog is particularly difficult or becomes aggressive, we reserve the right to refuse or stop the service for safety reasons.",
                          ),

                          const SizedBox(height: 32),

                          // Book Button
                          Center(
                            child: ElevatedButton(
                              onPressed: () => context.go('/book'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E6B56),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                  vertical: 16,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text('Book'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPolicySection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF475569),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}