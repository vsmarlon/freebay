import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ModerationActionType,
  ModerationTargetType,
  ReportReason,
  ReportStatus,
  ReportTargetType,
} from '@prisma/client';
import { CursorPageResponse } from '@/shared/dtos/pagination.dto';

export class AdminUserBriefResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id!: string;

  @ApiProperty({ example: 'Jane Doe' })
  readonly displayName!: string;

  @ApiPropertyOptional({ example: 'jane_doe', nullable: true })
  readonly username!: string | null;

  @ApiPropertyOptional({ nullable: true })
  readonly avatarUrl!: string | null;

  @ApiPropertyOptional({ nullable: true })
  readonly suspendedAt!: Date | null;
}

export class AdminReportResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id!: string;

  @ApiProperty({ enum: ReportTargetType })
  readonly targetType!: ReportTargetType;

  @ApiProperty({ enum: ReportReason })
  readonly reason!: ReportReason;

  @ApiPropertyOptional({ nullable: true })
  readonly description!: string | null;

  @ApiProperty({ enum: ReportStatus })
  readonly status!: ReportStatus;

  @ApiProperty()
  readonly createdAt!: Date;

  @ApiPropertyOptional({ nullable: true })
  readonly reviewedAt!: Date | null;

  @ApiPropertyOptional({ nullable: true })
  readonly reviewedById!: string | null;

  @ApiProperty({ type: AdminUserBriefResponse })
  readonly reporter!: AdminUserBriefResponse;

  @ApiPropertyOptional({ type: AdminUserBriefResponse, nullable: true })
  readonly reportedUser!: AdminUserBriefResponse | null;

  @ApiPropertyOptional({ nullable: true })
  readonly reportedPostId!: string | null;

  @ApiPropertyOptional({ nullable: true })
  readonly reportedDirectConversationId!: string | null;

  @ApiPropertyOptional({ nullable: true })
  readonly reportedOrderChatId!: string | null;

  @ApiPropertyOptional({ nullable: true })
  readonly reportedDirectMessageId!: string | null;

  @ApiPropertyOptional({ nullable: true })
  readonly reportedChatMessageId!: string | null;
}

export class AdminReportPageResponse extends CursorPageResponse {
  @ApiProperty({ type: [AdminReportResponse] })
  readonly items!: AdminReportResponse[];
}

export class ModerationActionResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id!: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly actorId!: string;

  @ApiProperty({ example: 'Admin' })
  readonly actorDisplayName!: string;

  @ApiProperty({ enum: ModerationTargetType })
  readonly targetType!: ModerationTargetType;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly targetId!: string;

  @ApiProperty({ enum: ModerationActionType })
  readonly action!: ModerationActionType;

  @ApiPropertyOptional({ nullable: true })
  readonly reason!: string | null;

  @ApiPropertyOptional({ nullable: true })
  readonly reportId!: string | null;

  @ApiProperty()
  readonly createdAt!: Date;
}

export class ModerationActionPageResponse extends CursorPageResponse {
  @ApiProperty({ type: [ModerationActionResponse] })
  readonly items!: ModerationActionResponse[];
}
