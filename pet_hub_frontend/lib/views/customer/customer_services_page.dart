import 'package:flutter/material.dart';
import '../../models/merchant_config.dart';
import 'customer_layout.dart';

class CustomerServicesPage extends StatefulWidget {
  final MerchantConfig config;
  final List<Map<String, dynamic>> activeServices;

  const CustomerServicesPage({
    super.key,
    required this.config,
    this.activeServices = const [],
  });

  @override
  State<CustomerServicesPage> createState() => _CustomerServicesPageState();
}

class _CustomerServicesPageState extends State<CustomerServicesPage> {
  int _selectedSubTabIndex = 0;
  final List<GlobalKey> _sectionKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _faqData = const [
    {
      'q': '1. How often should my dog be groomed?',
      'a': 'This depends on your dog\'s breed, coat type, lifestyle, and maintenance routine at home.\nGeneral recommendations:\n• Curly & Oodle coats: every 4–6 weeks\n• Long silky coats: every 4–6 weeks\n• Double coats: every 6–8 weeks\n• Short coats: every 6–10 weeks\n\nRegular grooming helps maintain skin health, coat condition, and comfort.'
    },
    {
      'q': '2. Why is my dog\'s coat matted even though I brush at home?',
      'a': 'Many mats form underneath the top layer of the coat and may not be visible immediately.\nCommon reasons include:\n• Surface brushing only\n• Incorrect brushing tools\n• Moisture trapped in the coat\n• Friction from harnesses or collars\n\nWe recommend using both a slicker brush and metal comb to ensure the coat is brushed through to the skin.'
    },
    {
      'q': '3. Will my dog need to be shaved if they are matted?',
      'a': 'Not always — however, severe matting may require clipping the coat short for welfare reasons.\nBrushing out dense matting can:\n• Be painful\n• Damage the skin\n• Cause stress and anxiety\n• Take excessive time\n\nYour dog\'s comfort and safety will always come first.'
    },
    {
      'q': '4. Why do groomers charge extra for dematting?',
      'a': 'Dematting requires significantly more:\n• Time\n• Labour\n• Handling\n• Equipment maintenance\n• Physical strain on the dog and groomer\n\nIn some cases, severe dematting may also increase the risk of skin irritation or injury.'
    },
    {
      'q': '5. Can double-coated dogs be shaved?',
      'a': 'Generally, double-coated breeds should not be shaved unless medically necessary or severely impacted by matting.\nShaving double coats may:\n• Affect coat texture\n• Alter regrowth\n• Reduce natural insulation\n• Increase risk of sun exposure\n\nWe usually recommend regular deshedding and coat maintenance instead.'
    },
    {
      'q': '6. What happens if my dog is anxious during grooming?',
      'a': 'Many dogs feel nervous during grooming, especially puppies or dogs with limited grooming experience.\nOur approach focuses on:\n• Gentle handling\n• Patience\n• Frequent breaks when needed\n• Creating positive grooming experiences\n\nWe always work within the dog\'s comfort level and welfare needs.'
    },
    {
      'q': '7. How long does a grooming appointment take?',
      'a': 'Appointment times vary depending on:\n• Breed and coat type\n• Coat condition\n• Grooming style requested\n• Dog behaviour and tolerance\n\nMost appointments range between 2–4 hours.'
    },
    {
      'q': '8. Can I stay and watch during grooming?',
      'a': 'For most dogs, grooming is less stressful when owners are not present. Dogs often become more anxious or excited when they can see their owners nearby.\n\nOur team will always contact you if needed during the appointment.'
    },
    {
      'q': '9. At what age should puppies start grooming?',
      'a': 'We recommend introducing puppies to grooming from around 12–16 weeks old, depending on vaccination status.\nEarly grooming helps puppies become comfortable with:\n• Brushing\n• Bathing\n• Drying\n• Clipping sounds\n• Nail trimming\n• Handling\n\nPositive early experiences often lead to calmer adult dogs.'
    },
    {
      'q': '10. How should I prepare my dog before their appointment?',
      'a': 'Before your appointment:\n• Allow your dog a toilet break\n• Avoid feeding a large meal immediately beforehand\n• Bring your dog on a secure lead\n• Inform us of any medical or behavioural concerns\n\nIf your dog has matting, sensitivity, or anxiety, please let us know in advance.'
    },
    {
      'q': '11. Do you groom elderly or special-needs dogs?',
      'a': 'Yes. Senior and special-needs dogs are welcome, and we always prioritise comfort and safety.\nPlease inform us of any health conditions (e.g. arthritis, heart issues, seizures, anxiety, lumps, or mobility problems) before the appointment.\nThese dogs may need extra care, slower handling, or additional support, which can sometimes involve extra fees for extended time or assistance.\n\nGrooming results may also be adjusted depending on your dog\'s comfort and tolerance, and perfect styling may not always be possible.\n\nIf a groom is considered unsafe or too stressful, we may need to modify or refuse the service. Your dog\'s wellbeing will always come first.'
    },
    {
      'q': '12. What products do you use?',
      'a': 'We use professional grooming products selected based on each dog\'s individual needs, including:\n• Coat type\n• Skin sensitivity\n• Coat condition\n• Breed requirements\n\nWe assess your dog on the day and choose products that best suit their skin and coat to ensure a safe and comfortable grooming experience.\nIf your dog has allergies or skin sensitivities, please let us know before the appointment.\n\nOur products are sourced from reputable Australian suppliers and professional grooming brands, including Igroom, Plush Puppy, Hyponic, Iv San Bernard, and Pet Esthe, among others.'
    },
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int index) {
    setState(() => _selectedSubTabIndex = index);
    final context = _sectionKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomerLayoutWrapper(
      config: widget.config,
      activeTab: CustomerTab.service,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;
          final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
          final horizontalPadding = isDesktop ? 48.0 : (isTablet ? 24.0 : 16.0);

          return SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sub-navigation bar
                  _buildSubTabBar(widget.config.primaryColor),
                  const SizedBox(height: 32),

                  // Section 1: Dog Grooming Prices
                  Container(key: _sectionKeys[0]),
                  _buildPricingSection(isDesktop, isTablet),
                  const SizedBox(height: 48),

                  // Section 2: Dog Coat Condition
                  Container(key: _sectionKeys[1]),
                  _buildCoatConditionSection(isDesktop, isTablet),
                  const SizedBox(height: 48),

                  // Section 3: Dog Grooming FAQ
                  Container(key: _sectionKeys[2]),
                  _buildFaqSection(isDesktop, isTablet),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubTabBar(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(6),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildSubTabButton(0, "Dog Grooming Prices", primaryColor),
          _buildSubTabButton(1, "Dog Coat Condition", primaryColor),
          _buildSubTabButton(2, "Dog Grooming FAQ", primaryColor),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label, Color primaryColor) {
    final isSelected = _selectedSubTabIndex == index;
    return InkWell(
      onTap: () => _scrollToSection(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF334155),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // --- 1. PRICING SECTION ---
  Widget _buildPricingSection(bool isDesktop, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text(
            "Dog Grooming Prices",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
        ),
        const SizedBox(height: 24),

        // Size Guide & Warning Header
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 320, child: _buildDogSizeCard()),
              const SizedBox(width: 24),
              Expanded(child: _buildYellowPricingNote()),
            ],
          )
        else
          Column(
            children: [
              _buildDogSizeCard(),
              const SizedBox(height: 16),
              _buildYellowPricingNote(),
            ],
          ),
        const SizedBox(height: 32),

        // Service 1: Wash and Dry
        _buildServiceCard(
          isDesktop: isDesktop,
          title: "Wash and Dry",
          description: "A basic wash service with shampoo and conditioner, including blow dry, brush, and dog cologne.",
          prices: const [
            _CoatPriceGroup(
              tag: "Short Hair",
              pricesText: "XS \$50, S \$55, M \$70\nL \$85, XL \$110, XXL \$135",
            ),
            _CoatPriceGroup(
              tag: "Long / Curly Hair",
              pricesText: "XS \$70, S \$75, M \$90\nL \$105, XL \$135, XXL \$165",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group A",
              pricesText: "XS \$80, S \$85, M \$95\nL \$115, XL \$150, XXL \$185",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group B",
              pricesText: "XS \$85, S \$90, M \$100\nL \$125, XL \$165, XXL \$200",
            ),
          ],
          assetPath: 'assets/images/folder/35.png',
        ),
        const SizedBox(height: 24),

        // Service 2: Wash and Tidy up
        _buildServiceCard(
          isDesktop: isDesktop,
          title: "Wash and Tidy up",
          description: "includes wash&dry, nail clip, eyes/ paw trim, tidy up head and tail, hygiene clip, ear clean and cologne",
          prices: const [
            _CoatPriceGroup(
              tag: "Short Hair",
              pricesText: "XS \$70, S \$75, M \$85\nL \$100, XL \$125, XXL \$150",
            ),
            _CoatPriceGroup(
              tag: "Long / Curly Hair",
              pricesText: "XS \$85, S \$95, M \$115\nL \$135, XL \$170, XXL \$200",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group A",
              pricesText: "XS \$90, S \$100, M \$125\nL \$150, XL \$195, XXL \$235",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group B",
              pricesText: "XS \$100, S \$110, M \$135\nL \$165, XL \$215, XXL \$255",
            ),
          ],
          assetPath: 'assets/images/folder/36.png',
        ),
        const SizedBox(height: 24),

        // Service 3: Wash Tidy & Pro-Deshedding
        _buildServiceCard(
          isDesktop: isDesktop,
          title: "Wash Tidy & Pro-Deshedding",
          description: "includes wash&dry, nail clip, eyes/ paw trim, hygiene clip, ear clean, full brush, removal of dead coat and cologne",
          prices: const [
            _CoatPriceGroup(
              tag: "Short Hair",
              pricesText: "XS \$105, S \$110, M \$120\nL \$135, XL \$160, XXL \$185",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group A",
              pricesText: "XS \$120, S \$130, M \$155\nL \$180, XL \$225, XXL \$265",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group B",
              pricesText: "XS \$130, S \$140, M \$165\nL \$200, XL \$245, XXL \$285",
            ),
          ],
          extraNote: "For double-coated dogs, this service is essential—not optional. Their dense undercoat traps dead hair and dander, leading to matting, skin irritation, and overheating if neglected. Regular sessions reduce shedding by up to 90% and protect your dog's natural insulation—cool in summer, warm in winter.",
          assetPath: 'assets/images/folder/37.png',
        ),
        const SizedBox(height: 24),

        // Service 4: Full Groom
        _buildServiceCard(
          isDesktop: isDesktop,
          title: "Full Groom",
          description: "A popular service includes wash & tidy up, hand scissoring for head, paw and tail, clipper cut the whole body, hair length < 1.3cm, provides a minimal style for your dog",
          prices: const [
            _CoatPriceGroup(
              tag: "Long / Curly Hair",
              pricesText: "XS \$115, S \$125, M \$150\nL \$180, XL \$215, XXL \$255",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group A",
              pricesText: "XS \$115, S \$125, M \$155\nL \$190, XL \$230, XXL \$280",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group B",
              pricesText: "XS \$125, S \$135, M \$170\nL \$210, XL \$245, XXL \$300",
            ),
          ],
          assetPath: 'assets/images/folder/38.png',
        ),
        const SizedBox(height: 24),

        // Service 5: Premium Style Groom
        _buildServiceCard(
          isDesktop: isDesktop,
          title: "Premium Style Groom",
          description: "Includes everything in our Wash & Tidy service. This groom is designed for dogs with a coat length of 1.5 cm or longer (additional charges may apply for de-matting). Rather than simply clipping the coat short all over, our groomers carefully style each dog to suit their unique features, aiming for a soft, fluffy, rounded \"teddy bear\" finish wherever the coat type allows.",
          prices: const [
            _CoatPriceGroup(
              tag: "Long / Curly Hair",
              pricesText: "XS from \$155, S from \$165, M from \$185\nL from \$235, XL from \$255, XXL ASQ",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group A",
              pricesText: "XS from \$125, S from \$140, M from \$165\nL from \$200, XL from \$245, XXL ASQ",
            ),
            _CoatPriceGroup(
              tag: "Double Coat Group B",
              pricesText: "XS from \$165, S from \$175, M from \$195\nL from \$245, XL from \$300, XXL ASQ",
            ),
          ],
          assetPath: 'assets/images/folder/15.png',
        ),
        const SizedBox(height: 36),

        // Full Price Table Image placed at the end of the pricing section
        const Text(
          "Complete Pricing Guide",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 3.5,
              child: Image.asset(
                'assets/images/dog_grooming_price_table.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(40),
                  color: const Color(0xFFF1F5F9),
                  child: const Column(
                    children: [
                      Icon(Icons.table_chart_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("Price Chart Image ('dog_grooming_price_table.png')", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDogSizeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF9EBA97),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dog Size:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          SizedBox(height: 12),
          Text("Extra Small Dog (under 3.5kg)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
          Text("Small Dog (3.6kg to 7kg)", style: TextStyle(fontSize: 13, color: Color(0xFF2D3748))),
          Text("Medium Dog (7.1kg to 15kg)", style: TextStyle(fontSize: 13, color: Color(0xFF2D3748))),
          Text("Large Dog (15.1kg -23kg)", style: TextStyle(fontSize: 13, color: Color(0xFF2D3748))),
          Text("Extra Large Dog (23.1kg to 30kg)", style: TextStyle(fontSize: 13, color: Color(0xFF2D3748))),
          Text("XXL Dog (30kg to 40kg)", style: TextStyle(fontSize: 13, color: Color(0xFF2D3748))),
          SizedBox(height: 16),
          Text("All 40kg dog is over XXL size", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildYellowPricingNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        "We kindly recommend that you review our service details and confirm your dog's coat condition before making a booking. Please note that if an incorrect size or coat condition is selected at the time of booking due to your dog's weight or coat condition, we will proceed with the billing based on the actual size and coat condition of your pet.",
        style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF78350F), fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildServiceCard({
    required bool isDesktop,
    required String title,
    required String description,
    required List<_CoatPriceGroup> prices,
    String? extraNote,
    required String assetPath,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.4)),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: prices.map((p) => _buildCoatPriceItem(p)).toList(),
                  ),
                  if (extraNote != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        extraNote,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF78350F), height: 1.4),
                      ),
                    ),
                  ],
                ],
              );

              final imageBox = ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: isDesktop ? 280 : double.infinity,
                  height: 180,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE2E8F0),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported_outlined, size: 36, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 8),
                          Text(
                            assetPath,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 24),
                    imageBox,
                  ],
                );
              } else {
                return Column(
                  children: [
                    imageBox,
                    const SizedBox(height: 16),
                    content,
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoatPriceItem(_CoatPriceGroup group) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2F6343),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              group.tag,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            group.pricesText,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // --- 2. COAT CONDITION SECTION ---
  Widget _buildCoatConditionSection(bool isDesktop, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildWelcomeCard()),
              const SizedBox(width: 24),
              Expanded(flex: 3, child: _buildImportantDetailsText()),
            ],
          )
        else
          Column(
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 20),
              _buildImportantDetailsText(),
            ],
          ),
        const SizedBox(height: 40),
        const Center(
          child: Text(
            "Dog Coat Condition",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: isDesktop ? 0.85 : 1.1,
              children: const [
                _CoatTypeCard(
                  title: "Short-haired Dogs",
                  description: "Short hair dog breeds like Boston terrier, French bulldog, Dachshund, Kelpie, Chihuahua, Beagle, Pug, etc.",
                  icon: Icons.pets,
                ),
                _CoatTypeCard(
                  title: "Long/ Curly-haired Dogs",
                  description: "Long/Curly hair dog breeds like all Poodle, Bichon Frise, Poodle mix (Cavoodle, Moodle, Groodle), Maltese, Shi Tzu, Schnauzer, Yorkshire, Westie, Spaniels, Lagotto etc.",
                  icon: Icons.pets,
                ),
                _CoatTypeCard(
                  title: "Double coat hair Dogs",
                  description: "Double coat hair dog breeds like Golden Retriever, Collies, Shepherd, ChowChow, Pomeranian, Spitz, Shibu Inu, Samoyed, etc. We separate Group A and Group B double coat, please read our price guide before making an appointment.",
                  icon: Icons.pets,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFC2D3BD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome to\nPawparazzi Pet",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          SizedBox(height: 16),
          Text(
            "We are excited to provide your dog with top-notch grooming services. To ensure a smooth and satisfactory grooming experience, please read and review the following important details.",
            style: TextStyle(fontSize: 14, color: Color(0xFF4A5568), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantDetailsText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "1. Before booking a grooming appointment, please confirm your dog's coat condition and weight. If there is a discrepancy in your booking, we will review it on the day of the service. It is important to provide accurate information to avoid any issues or misunderstandings.",
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4A5568)),
        ),
        SizedBox(height: 12),
        Text(
          "2. To accept your dog for grooming, you must review and agree to our salon policies, service details, terms, and conditions. It is essential that you have read and understood these terms for us to provide the best care for your dog.",
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4A5568)),
        ),
        SizedBox(height: 12),
        Text(
          "3. The grooming times listed on our website are general estimates. The exact duration of the grooming session depends on several factors, including:\n- Dog Coat Condition: Tangles, mats, and the general condition of your dog's coat.\n- Dog Behavior: Your dog's temperament and how they respond to grooming.\nOn average, grooming appointments take between 1.5 to 4 hours. Please note that scissor cuts and Asian Fusion style cuts may require additional time.",
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4A5568)),
        ),
      ],
    );
  }

  // --- 3. FAQ SECTION ---
  Widget _buildFaqSection(bool isDesktop, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Frequently Asked Questions",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            int columns = isDesktop ? 2 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _faqData.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                mainAxisExtent: isDesktop ? 340 : null,
              ),
              itemBuilder: (context, index) {
                final faq = _faqData[index];
                return _FaqCard(question: faq['q']!, answer: faq['a']!);
              },
            );
          },
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Still Have Questions?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
              ),
              SizedBox(height: 8),
              Text(
                "We're always happy to discuss your dog's individual coat care, grooming routine, and maintenance needs. Our goal is to provide a safe, comfortable, and professional grooming experience tailored to every dog.",
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoatPriceGroup {
  final String tag;
  final String pricesText;

  const _CoatPriceGroup({required this.tag, required this.pricesText});
}

class _CoatTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _CoatTypeCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFC2D3BD),
            child: Icon(icon, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                description,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFE6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                answer,
                style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}