import 'car_model.dart';

List<CarModel> dashboardLeads = [
  CarModel(
    id: "1",
    make: "BMW",
    model: "M4 Competition",
    year: "2022",
    reg: "AB12 CDE",
    color: "San Marino Blue",
    mileage: 12500,
    price: 55000,
    status: CarStatus.lead,
    customerName: "John Doe",
    phoneNumber: "07123456789",
    images: [
      CarImage(
        id: "img1",
        url:
            "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&q=80&w=800",
        isCover: true,
      ),
      CarImage(
        id: "img2",
        url:
            "https://images.unsplash.com/photo-1617814076367-b757c798954b?auto=format&fit=crop&q=80&w=800",
      ),
      CarImage(
        id: "img3",
        url:
            "https://images.unsplash.com/photo-1603386329225-868f9b1ee6c9?auto=format&fit=crop&q=80&w=800",
      ),
    ],
  ),
  CarModel(
    id: "2",
    make: "Audi",
    model: "A5 Competition",
    year: "2026",
    reg: "AB12 CDE",
    color: "San Marino Blue",
    mileage: 12500,
    price: 105000,
    status: CarStatus.lead,
    customerName: "John Doe",
    phoneNumber: "07123456789",
    images: [
      CarImage(
        id: "img1",
        url:
            "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&q=80&w=800",
        isCover: true,
      ),
      CarImage(
        id: "img2",
        url:
            "https://images.unsplash.com/photo-1617814076367-b757c798954b?auto=format&fit=crop&q=80&w=800",
      ),
      CarImage(
        id: "img3",
        url:
            "https://images.unsplash.com/photo-1603386329225-868f9b1ee6c9?auto=format&fit=crop&q=80&w=800",
      ),
    ],
  ),
  CarModel(
    id: "3",
    make: "ford",
    model: "Mustang GT",
    year: "2022",
    reg: "AB12 CDE",
    color: "San Marino Blue",
    mileage: 12500,
    price: 55000,
    status: CarStatus.lead,
    customerName: "John Doe",
    phoneNumber: "07123456789",
    images: [
      CarImage(
        id: "img1",
        url:
            "https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&q=80&w=800",
        isCover: true,
      ),
      CarImage(
        id: "img2",
        url:
            "https://images.unsplash.com/photo-1617814076367-b757c798954b?auto=format&fit=crop&q=80&w=800",
      ),
      CarImage(
        id: "img3",
        url:
            "https://images.unsplash.com/photo-1603386329225-868f9b1ee6c9?auto=format&fit=crop&q=80&w=800",
      ),
    ],
  ),
  // Add more mock cars here...
];
