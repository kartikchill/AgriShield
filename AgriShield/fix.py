with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "r", encoding="utf-8") as f:
    code = f.read()

location_textfield = """
  Widget _LocationTextField(String hint, TextEditingController controller) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC7EBD1)),
        borderRadius: BorderRadius.circular(8)),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.notoSans(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
"""
code = code.rsplit('}', 1)[0] + location_textfield

with open(r"D:\PDD2\AgriShield\lib\screens\disease_risk_screen.dart", "w", encoding="utf-8") as f:
    f.write(code)
