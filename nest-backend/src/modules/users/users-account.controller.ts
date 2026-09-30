import {
  Controller,
  Body,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Query,
} from "@nestjs/common";
import { FileInterceptor } from "@nestjs/platform-express";
import { memoryStorage } from "multer";
import { ApiTags } from "@nestjs/swagger";
import { UserDatabaseRepository } from "@/modules/auth/data/repositories/user-database.repository";
import {
  GetUserStatsUseCase,
  RegisterPhoneUseCase,
  VerifyPhoneUseCase,
  GetProfileUseCase,
  UpdateProfileUseCase,
  UpdateFcmTokenUseCase,
  RequestAccountDeletionUseCase,
  CancelAccountDeletionUseCase,
  ExportUserDataUseCase,
} from "./usecases";
import {
  GetAuth,
  PostAuth,
  PatchAuth,
  DeleteAuth,
  CurrentUserId,
} from "@/shared/decorators";
import {
  UpdateProfileDTO,
  UpdateFcmTokenDTO,
  RegisterPhoneDTO,
  VerifyPhoneDTO,
  OffsetPaginationQueryDTO,
  CloseFriendCandidatesQueryDTO,
} from "./dtos/user.dto";
import { ManageSafetyListUseCase } from './usecases/manage-safety-list.usecase';
import {
  UserResponse,
  UserStatsResponse,
  AccountDeletionResponse,
  toUserResponse,
} from "./dtos/user-response.class";
import { validateImageFile } from "@/shared/utils/image-upload.utils";
import { saveUpload } from "@/shared/utils/file.utils";

@ApiTags("Users")
@Controller("users")
export class UsersAccountController {
  constructor(
    private readonly userRepository: UserDatabaseRepository,
    private readonly getUserStatsUseCase: GetUserStatsUseCase,
    private readonly registerPhoneUseCase: RegisterPhoneUseCase,
    private readonly verifyPhoneUseCase: VerifyPhoneUseCase,
    private readonly getProfileUseCase: GetProfileUseCase,
    private readonly updateProfileUseCase: UpdateProfileUseCase,
    private readonly updateFcmTokenUseCase: UpdateFcmTokenUseCase,
    private readonly requestAccountDeletionUseCase: RequestAccountDeletionUseCase,
    private readonly cancelAccountDeletionUseCase: CancelAccountDeletionUseCase,
    private readonly exportUserDataUseCase: ExportUserDataUseCase,
    private readonly safetyLists: ManageSafetyListUseCase,
  ) {}

  @GetAuth('me/close-friends/candidates', 'Search my followers and close friends')
  getCloseFriendCandidates(@CurrentUserId() userId: string, @Query() query: CloseFriendCandidatesQueryDTO) {
    return this.safetyLists.candidates(userId, query.q ?? '', query.selected === 'true', query.limit ?? 20, query.offset ?? 0);
  }

  @GetAuth('me/close-friends', 'List my close friends')
  getCloseFriends(@CurrentUserId() userId: string, @Query() query: OffsetPaginationQueryDTO) {
    return this.safetyLists.list(userId, 'closeFriends', query.limit ?? 20, query.offset ?? 0);
  }

  @PostAuth('me/close-friends/:memberId', { summary: 'Add a follower to close friends', responseStatus: 201 })
  addCloseFriend(@CurrentUserId() userId: string, @Param('memberId', ParseUUIDPipe) memberId: string) {
    return this.safetyLists.change(userId, memberId, 'closeFriends', true);
  }

  @PatchAuth('me/close-friends/:memberId/remove', 'Remove a close friend')
  removeCloseFriend(@CurrentUserId() userId: string, @Param('memberId', ParseUUIDPipe) memberId: string) {
    return this.safetyLists.change(userId, memberId, 'closeFriends', false);
  }

  @GetAuth('me/restricted', 'List my restricted users')
  getRestricted(@CurrentUserId() userId: string, @Query() query: OffsetPaginationQueryDTO) {
    return this.safetyLists.list(userId, 'restricted', query.limit ?? 20, query.offset ?? 0);
  }

  @PostAuth('me/restricted/:memberId', { summary: 'Restrict a user', responseStatus: 201 })
  restrict(@CurrentUserId() userId: string, @Param('memberId', ParseUUIDPipe) memberId: string) {
    return this.safetyLists.change(userId, memberId, 'restricted', true);
  }

  @PatchAuth('me/restricted/:memberId/remove', 'Remove a restriction')
  unrestrict(@CurrentUserId() userId: string, @Param('memberId', ParseUUIDPipe) memberId: string) {
    return this.safetyLists.change(userId, memberId, 'restricted', false);
  }

  @GetAuth("me", {
    summary: "Get current user profile",
    responseType: UserResponse,
    errors: [{ status: 404, description: "User not found" }],
  })
  async getMe(@CurrentUserId() userId: string) {
    return this.getProfileUseCase.execute({ userId, includePrivate: true });
  }

  @GetAuth("me/stats", {
    summary: "Get current user stats",
    responseType: UserStatsResponse,
  })
  async getMyStats(@CurrentUserId() userId: string) {
    return this.getUserStatsUseCase.execute({ userId });
  }

  @GetAuth("me/export", {
    summary: "Export all personal data",
    description:
      "Returns every record tied to the account as a single JSON document (LGPD data portability).",
    throttle: { limit: 3, ttl: 3600000 },
    errors: [{ status: 404, description: "User not found" }],
  })
  async exportMyData(@CurrentUserId() userId: string) {
    return this.exportUserDataUseCase.execute({ userId });
  }

  @DeleteAuth("me", {
    summary: "Request account deletion",
    description:
      "Starts the 30-day deletion window: sessions are revoked, listings are paused, and the account is anonymized by the purge job unless cancelled.",
    responseType: AccountDeletionResponse,
    throttle: { limit: 3, ttl: 3600000 },
    errors: [
      { status: 404, description: "User not found" },
      {
        status: 409,
        description: "Account has open orders, disputes or a wallet balance",
      },
    ],
  })
  async requestAccountDeletion(@CurrentUserId() userId: string) {
    return this.requestAccountDeletionUseCase.execute({ userId });
  }

  @PatchAuth("me/deletion/cancel", {
    summary: "Cancel a pending account deletion",
    errors: [
      { status: 400, description: "No pending deletion" },
      { status: 404, description: "User not found" },
    ],
  })
  async cancelAccountDeletion(@CurrentUserId() userId: string) {
    return this.cancelAccountDeletionUseCase.execute({ userId });
  }

  @PatchAuth("me", {
    summary: "Update profile",
    bodyType: UpdateProfileDTO,
    responseType: UserResponse,
    errors: [{ status: 404, description: "User not found" }],
  })
  async updateProfile(
    @CurrentUserId() userId: string,
    @Body() body: UpdateProfileDTO,
  ) {
    return this.updateProfileUseCase.execute({ userId, ...body });
  }

  @PostAuth("me/avatar", {
    summary: "Upload profile picture",
    description:
      "Uploads an image to be used as profile avatar. Accepts JPEG, PNG, WebP, GIF up to 5MB.",
    responseType: UserResponse,
    httpCode: HttpStatus.OK,
  })
  @UseInterceptors(
    FileInterceptor("avatar", {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadAvatar(
    @CurrentUserId() userId: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.uploadProfileImage(userId, file, "avatar", 5 * 1024 * 1024);
  }

  @PostAuth("me/banner", {
    summary: "Upload profile banner picture",
    description:
      "Uploads an image to be used as profile banner. Accepts JPEG, PNG, WebP, GIF up to 8MB.",
    responseType: UserResponse,
    httpCode: HttpStatus.OK,
  })
  @UseInterceptors(
    FileInterceptor("banner", {
      storage: memoryStorage(),
      limits: { fileSize: 8 * 1024 * 1024 },
    }),
  )
  async uploadBanner(
    @CurrentUserId() userId: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.uploadProfileImage(userId, file, "banner", 8 * 1024 * 1024);
  }

  @PostAuth("me/phone", {
    summary: "Register phone number for verification",
    bodyType: RegisterPhoneDTO,
    throttle: {
      short: { limit: 3, ttl: 60000 },
      medium: { limit: 5, ttl: 60000 },
    },
    httpCode: HttpStatus.OK,
  })
  async registerPhone(
    @CurrentUserId() userId: string,
    @Body() body: RegisterPhoneDTO,
  ) {
    return this.registerPhoneUseCase.execute({ userId, phone: body.phone });
  }

  @PostAuth("me/phone/verify", {
    summary: "Verify phone number using code",
    bodyType: VerifyPhoneDTO,
    throttle: {
      short: { limit: 5, ttl: 60000 },
      medium: { limit: 10, ttl: 60000 },
    },
    httpCode: HttpStatus.OK,
  })
  async verifyPhone(
    @CurrentUserId() userId: string,
    @Body() body: VerifyPhoneDTO,
  ) {
    return this.verifyPhoneUseCase.execute({ userId, code: body.code });
  }

  @PatchAuth("me/fcm-token", {
    summary: "Update FCM token",
    bodyType: UpdateFcmTokenDTO,
  })
  async updateFcmToken(
    @CurrentUserId() userId: string,
    @Body() body: UpdateFcmTokenDTO,
  ) {
    const result = await this.updateFcmTokenUseCase.execute({
      userId,
      ...body,
    });
    if (result.isLeft()) return result;
    return { success: true };
  }

  private async uploadProfileImage(
    userId: string,
    file: Express.Multer.File | undefined,
    field: "avatar" | "banner",
    maxSizeBytes: number,
  ) {
    if (!file) throw new BadRequestException("Imagem é obrigatória");
    const mimeError = validateImageFile(file, maxSizeBytes);
    if (mimeError) throw new BadRequestException(mimeError);

    const imageUrl = saveUpload(file, field);
    const updateResult =
      field === "avatar"
        ? await this.userRepository.update(userId, { avatarUrl: imageUrl })
        : await this.userRepository.update(userId, { bannerUrl: imageUrl });
    if (updateResult.isLeft()) return updateResult;
    return toUserResponse(updateResult.value, undefined, true);
  }
}
