//
//  SchedulePTViewModel.swift
//  SmartGym
//

import Foundation
import Supabase

@MainActor
@Observable
final class SchedulePTViewModel {
    var trainers: [PTTrainer] = []
    var isLoading = false
    var isSubmitting = false
    var error: String?
    var selectedTrainerId: String?
    var preferredTime: String = ""
    var message: String = ""
    var requestSent = false

    private let trainerRepository = PTTrainerRepository()
    private let client = AppSupabase.client

    var canSubmit: Bool {
        // Require at least a trainer or a non-empty message, mirroring Android.
        (selectedTrainerId != nil && !selectedTrainerId!.isEmpty) || !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadTrainers(member: Member?) async {
        guard let member else {
            error = "No member profile linked. Contact your gym to link your account."
            return
        }
        isLoading = true
        error = nil
        do {
            trainers = try await trainerRepository.getTrainersByGymId(gymId: member.gymId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func submitRequest(member: Member?, gym: Gym?) async {
        guard let member, let gym else { return }
        guard canSubmit else { return }

        isSubmitting = true
        error = nil
        do {
            struct InsertRow: Encodable {
                let gym_id: String
                let member_id: String
                let trainer_id: String?
                let preferred_date: String?
                let preferred_time: String?
                let message: String?
            }

            let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTime = preferredTime.trimmingCharacters(in: .whitespacesAndNewlines)

            let row = InsertRow(
                gym_id: gym.id,
                member_id: member.id,
                trainer_id: selectedTrainerId,
                preferred_date: nil,
                preferred_time: trimmedTime.isEmpty ? nil : trimmedTime,
                message: trimmedMessage.isEmpty ? nil : trimmedMessage
            )

            _ = try await client
                .from("pt_session_requests")
                .insert(row)
                .execute()

            // Reset form so user can send another request
            selectedTrainerId = nil
            preferredTime = ""
            message = ""
            requestSent = true
        } catch {
            self.error = error.localizedDescription
        }
        isSubmitting = false
    }
}

