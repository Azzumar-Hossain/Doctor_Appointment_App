import 'dart:convert';
import 'package:demo_appointment/core/api_client.dart';
import 'package:demo_appointment/data/auth_service.dart';
import 'package:demo_appointment/models/location_models.dart';
import 'package:demo_appointment/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController =
      TextEditingController(); // present_address details
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _doctorFeeController = TextEditingController();

  String gender = "Male";
  String patientType = "Self";

  List<dynamic> searchResults = [];
  bool isLoading = false; // used for patient search and other small loads

  // Appointment-related fields
  DateTime? selectedDate;
  List<dynamic> doctorList = [];
  Map<String, dynamic>? selectedDoctor;

  List<dynamic> timeSlots = [];
  Map<String, dynamic>? selectedTimeSlot;

  String selectedAppointmentType = "New";
  String selectedPaymentMethod = "Cash";

  // --- Location state ---
  bool loadingLocations = false;
  bool submitting = false; // used for submit button state

  List<Division> divisions = [];
  Division? selectedDivision;
  District? selectedDistrict;
  Upazila? selectedUpazila;
  Union? selectedUnion;

  List<District> districts = [];
  List<Upazila> upazilas = [];
  List<Union> unions = [];

  // --------------------------

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  // 🔹 Load all divisions (with nested district/upazila/union)
  Future<void> _loadDivisions() async {
    setState(() => loadingLocations = true);
    try {
      final data = await LocationService().fetchDivisions();
      setState(() {
        divisions = data;
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load location data")),
        );
      }
    } finally {
      if (mounted) setState(() => loadingLocations = false);
    }
  }

  // 🔹 Fetch patient list
  Future<void> fetchPatientList(String query) async {
    if (query.length < 3) {
      setState(() => searchResults = []);
      return;
    }
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          "http://20.20.20.37:8080/proyashospital/api/get-patient-list?name=$query",
        ),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          searchResults = data;
        });
      } else {
        setState(() => searchResults = []);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => searchResults = []);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🔹 Autofill form
  void fillPatientData(Map<String, dynamic> patient) {
    setState(() {
      _nameController.text = patient['name'] ?? "";
      _mobileController.text = patient['mobile_number'] ?? "";
      _ageController.text = patient['age'] ?? "";
      _addressController.text = patient['present_address'] ?? "";

      if (patient['sex'] == 1) {
        gender = "Male";
      } else if (patient['sex'] == 2) {
        gender = "Female";
      } else if (patient['sex'] == 3) {
        gender = "Baby";
      }

      if (patient['type'] == "self") {
        patientType = "Self";
      } else if (patient['type'] == "cardholder") {
        patientType = "Card Holder";
      }

      searchResults = [];
      _searchController.clear();
    });
  }

  // 🔹 Fetch doctors by date
  Future<void> fetchDoctorsByDate(DateTime date) async {
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.get(
        Uri.parse(
          "http://20.20.20.37:8080/proyashospital/api/assigned_doctors?date=$formattedDate",
        ),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          doctorList = data;
          selectedDoctor = null;
          _doctorController.clear();
          selectedTimeSlot = null;
          timeSlots.clear();
          _timeController.clear();
          _doctorFeeController.clear();
        });
      }
    } catch (e) {
      debugPrint("Doctor API Error: $e");
    }
  }

  // 🔹 Fetch time slots
  Future<void> fetchTimeSlots(int doctorId, String date) async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://20.20.20.37:8080/proyashospital/api/load-appointment-time/?doctor_id=$doctorId&date=$date",
        ),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          timeSlots = data;
          selectedTimeSlot = null;
          _timeController.clear();
        });
      } else {
        setState(() => timeSlots = []);
      }
    } catch (e) {
      debugPrint("Error fetching time slots: $e");
      setState(() => timeSlots = []);
    }
  }

  // 🔹 Fetch Doctor's Fee
  Future<void> fetchDoctorFee(int doctorId) async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://20.20.20.37:8080/proyashospital/api/load-doctor-fees?id=$doctorId",
        ),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        if (data.isNotEmpty && mounted) {
          final fee = data.first['amount']?.toString() ?? "";
          setState(() {
            _doctorFeeController.text = fee;
          });
        }
      } else {
        debugPrint(
          "⚠️ Failed to fetch doctor fee. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("❌ Error fetching doctor fee: $e");
    }
  }

  // 🔹 Submit appointment (preserves your API style but improves logging & state)
  Future<void> submitAppointment() async {
    if (selectedDate == null ||
        selectedDoctor == null ||
        selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please select date, doctor, and time"),
        ),
      );
      return;
    }

    // set submitting state (for button)
    if (mounted)
      setState(() {
        submitting = true;
      });

    try {
      final formattedDate =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

      // ✅ Get token
      final auth = AuthService();
      var token = await auth.getToken();

      // defensive: trim newline/space characters that sometimes sneak in
      token = token?.trim();

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🔐 Session expired. Please login again."),
            ),
          );
        }
        return;
      }

      // ✅ Prepare request payload (we include both 'token' and 'api_token' to be safe)
      final requestBody = {
        "patient_type": patientType.toLowerCase(),
        "name": _nameController.text,
        "patient_id": "",
        "mobile_number": _mobileController.text,
        "patient_id_no": "",
        "age": _ageController.text,
        "age_parameter": "y",
        "present_address": _addressController.text,
        "division_id": selectedDivision?.id,
        "district_id": selectedDistrict?.id,
        "upazila_id": selectedUpazila?.id,
        "union_id": selectedUnion?.id,
        "sex": gender == "Male"
            ? 1
            : gender == "Female"
            ? 2
            : 3,
        "date": formattedDate,
        "doctor_id": selectedDoctor?['id'],
        "schedule_id": selectedTimeSlot?['id'],
        "time": "${selectedTimeSlot?['in_time']}",
        "serial_num": 1,
        "status": 1,
        "doctor_fee_id": selectedDoctor?['fee_id'] ?? 0,
        "doctor_fees_id": selectedDoctor?['fee_id'] ?? 0,
        "doctor_fee": _doctorFeeController.text,
        "payable_amount": _doctorFeeController.text,
        "payment_way_id": selectedPaymentMethod == "Cash"
            ? 1
            : selectedPaymentMethod == "Card"
            ? 2
            : 3,
        "invoice_type": 0,
        "account_id": 1,
        // include both keys in case server expects either:
        "token": token,
        "api_token": token,
      };

      // 📡 Debug logs
      debugPrint("📤 Sending appointment request...");
      debugPrint("🔑 Token (trimmed): $token");
      debugPrint("📅 Date: $formattedDate");
      debugPrint("📦 Payload: $requestBody");

      // ✅ API Request (queryParameters because your API expects URL params)
      final response = await ApiClient.dio.post(
        "employee/online_appointment_store",
        queryParameters: requestBody,
      );

      // helpful: show the actual request URL if available
      try {
        debugPrint("🔗 Request URL: ${response.realUri}");
      } catch (_) {}

      debugPrint("📥 Raw response: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;

        // Some endpoints return boolean true or string "success"
        if (data["status"] == true || data["status"] == "success") {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data["message"] ?? "✅ Appointment booked successfully!",
                ),
                backgroundColor: Colors.green,
              ),
            );
            clearForm();
          }
        } else {
          // server returned a failure; print details to console
          debugPrint("❌ Server rejected request: ${data["message"]}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "❌ Failed: ${data["message"] ?? "Unknown error"}",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        debugPrint("❌ Unexpected status: ${response.statusCode}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚠️ Server error: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint("🔥 Exception while submitting appointment: $e");
      debugPrint("📍 Stacktrace: $st");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Network error or unexpected issue."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted)
        setState(() {
          submitting = false;
        });
    }
  }

  // 🔹 Clear Form
  void clearForm() {
    setState(() {
      _searchController.clear();
      _nameController.clear();
      _mobileController.clear();
      _ageController.clear();
      _addressController.clear();
      _doctorController.clear();
      _timeController.clear();
      _doctorFeeController.clear();
      gender = "Male";
      patientType = "Self";
      selectedDoctor = null;
      selectedTimeSlot = null;
      selectedAppointmentType = "New";
      selectedPaymentMethod = "Cash";
      doctorList = [];
      timeSlots = [];
      selectedDate = null;

      // location resets
      selectedDivision = null;
      selectedDistrict = null;
      selectedUpazila = null;
      selectedUnion = null;
      districts = [];
      upazilas = [];
      unions = [];
    });
  }

  // 🔹 Show confirmation popup
  Future<void> showClearConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear Form"),
        content: const Text("Are you sure you want to clear the form?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Form cleared successfully!"),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Book Appointment",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Search patient section
            _buildSectionHeader("Find Existing Patient"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: "Search by Name or Mobile",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                      onChanged: fetchPatientList,
                    ),
                    if (searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final patient = searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.person, size: 20),
                              ),
                              title: Text(
                                patient['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                "${patient['mobile_number'] ?? ''} • Age: ${patient['age'] ?? ''}",
                              ),
                              onTap: () => fillPatientData(patient),
                              shape: Border(
                                bottom: index < searchResults.length - 1
                                    ? BorderSide(color: Colors.grey.shade300)
                                    : BorderSide.none,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Patient details form
            _buildSectionHeader("Patient Information"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildModernTextField(
                      "Patient Name",
                      Icons.person_outline,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      "Mobile Number",
                      Icons.phone,
                      controller: _mobileController,
                    ),
                    const SizedBox(height: 16),
                    _buildModernTextField(
                      "Age",
                      Icons.cake,
                      controller: _ageController,
                    ),
                    const SizedBox(height: 16),

                    // ====== NEW: Location dropdowns (Division -> District -> Upazila -> Union) ======
                    // Division
                    loadingLocations
                        ? const SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        : _buildModernDropdown<Division>(
                            "Division",
                            Icons.location_city,
                            value: selectedDivision,
                            items: divisions
                                .map(
                                  (d) => DropdownMenuItem<Division>(
                                    value: d,
                                    child: Text(d.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (Division? val) {
                              setState(() {
                                selectedDivision = val;
                                selectedDistrict = null;
                                selectedUpazila = null;
                                selectedUnion = null;

                                districts = val?.districts ?? [];
                                upazilas = [];
                                unions = [];
                              });
                            },
                          ),

                    const SizedBox(height: 12),

                    // District
                    _buildModernDropdown<District>(
                      "District",
                      Icons.domain,
                      value: selectedDistrict,
                      items: districts
                          .map(
                            (d) => DropdownMenuItem<District>(
                              value: d,
                              child: Text(d.name),
                            ),
                          )
                          .toList(),
                      onChanged: (District? val) {
                        setState(() {
                          selectedDistrict = val;
                          selectedUpazila = null;
                          selectedUnion = null;

                          upazilas = val?.upazilas ?? [];
                          unions = [];
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Upazila
                    _buildModernDropdown<Upazila>(
                      "Upazila",
                      Icons.map,
                      value: selectedUpazila,
                      items: upazilas
                          .map(
                            (u) => DropdownMenuItem<Upazila>(
                              value: u,
                              child: Text(u.name),
                            ),
                          )
                          .toList(),
                      onChanged: (Upazila? val) {
                        setState(() {
                          selectedUpazila = val;
                          selectedUnion = null;
                          unions = val?.unions ?? [];
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Union
                    _buildModernDropdown<Union>(
                      "Union",
                      Icons.home_work,
                      value: selectedUnion,
                      items: unions
                          .map(
                            (u) => DropdownMenuItem<Union>(
                              value: u,
                              child: Text(u.name),
                            ),
                          )
                          .toList(),
                      onChanged: (Union? val) {
                        setState(() {
                          selectedUnion = val;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Detailed Address (present_address)
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Address (Road, House, etc.)",
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Gender dropdown
                    _buildModernDropdown(
                      "Gender",
                      Icons.transgender,
                      value: gender,
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(
                          value: "Female",
                          child: Text("Female"),
                        ),
                        DropdownMenuItem(value: "Baby", child: Text("Baby")),
                      ],
                      onChanged: (val) =>
                          setState(() => gender = val ?? "Male"),
                    ),
                    const SizedBox(height: 16),

                    // Patient Type dropdown
                    _buildModernDropdown(
                      "Patient Type",
                      Icons.badge,
                      value: patientType,
                      items: const [
                        DropdownMenuItem(value: "Self", child: Text("Self")),
                        DropdownMenuItem(
                          value: "Card Holder",
                          child: Text("Card Holder"),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => patientType = val ?? "Self"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Appointment details
            _buildSectionHeader("Appointment Details"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date Picker
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Select Date",
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                          await fetchDoctorsByDate(picked);
                        }
                      },
                      controller: TextEditingController(
                        text: selectedDate == null
                            ? ""
                            : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Doctor Dropdown
                    if (selectedDate != null)
                      _buildModernDropdown<Map<String, dynamic>>(
                        "Select Doctor",
                        Icons.medical_services,
                        value: selectedDoctor,
                        items: doctorList
                            .map<DropdownMenuItem<Map<String, dynamic>>>(
                              (doc) => DropdownMenuItem<Map<String, dynamic>>(
                                value: doc as Map<String, dynamic>,
                                child: Text(
                                  "${doc['name']} (${doc['department']})",
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedDoctor = val;
                            selectedTimeSlot = null;
                            timeSlots.clear();
                            _timeController.clear();
                            _doctorFeeController.clear();
                          });
                          if (selectedDate != null && val != null) {
                            final formatted =
                                "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                            fetchTimeSlots(val['id'], formatted);
                            fetchDoctorFee(val['id']);
                          }
                        },
                      ),

                    if (selectedDoctor != null) const SizedBox(height: 16),

                    // Time Slot Dropdown
                    if (selectedDoctor != null && timeSlots.isNotEmpty)
                      _buildModernDropdown<Map<String, dynamic>>(
                        "Select Time Schedule",
                        Icons.access_time,
                        value: selectedTimeSlot,
                        items: timeSlots
                            .map<DropdownMenuItem<Map<String, dynamic>>>(
                              (t) => DropdownMenuItem<Map<String, dynamic>>(
                                value: t as Map<String, dynamic>,
                                child: Text(
                                  "${t['in_time']} - ${t['out_time']}",
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedTimeSlot = val;
                          });
                        },
                      ),

                    const SizedBox(height: 16),

                    // Doctor Fee
                    TextField(
                      controller: _doctorFeeController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Doctor Fee",
                        prefixIcon: const Icon(Icons.money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 🔹 Appointment Type & Payment
            _buildSectionHeader("Appointment Settings"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildModernDropdown(
                      "Appointment Type",
                      Icons.event_note,
                      value: selectedAppointmentType,
                      items: const [
                        DropdownMenuItem(value: "New", child: Text("New")),
                        DropdownMenuItem(
                          value: "Follow-up",
                          child: Text("Follow-up"),
                        ),
                      ],
                      onChanged: (val) => setState(
                        () => selectedAppointmentType = val ?? "New",
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildModernDropdown(
                      "Payment Method",
                      Icons.payment,
                      value: selectedPaymentMethod,
                      items: const [
                        DropdownMenuItem(value: "Cash", child: Text("Cash")),
                        DropdownMenuItem(value: "Card", child: Text("Card")),
                        DropdownMenuItem(
                          value: "Online",
                          child: Text("Online"),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => selectedPaymentMethod = val ?? "Cash"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Clear Form Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: showClearConfirmation,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.clear, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Clear Form",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Submit Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: submitting ? null : submitAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: submitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Confirm",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildModernTextField(
    String label,
    IconData icon, {
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildModernDropdown<T>(
    String label,
    IconData icon, {
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          hint: Text(
            'Select $label',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      ),
    );
  }
}
