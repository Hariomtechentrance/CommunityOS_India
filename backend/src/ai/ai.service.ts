import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GeminiService } from './gemini.service';

const SUPPORTED_LANGUAGES: Record<string, string> = {
  en: 'English',
  hi: 'Hindi',
  mr: 'Marathi',
  kn: 'Kannada',
  ta: 'Tamil',
  te: 'Telugu',
  bn: 'Bengali',
  gu: 'Gujarati',
  ml: 'Malayalam',
  pa: 'Punjabi',
};

@Injectable()
export class AiService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly gemini: GeminiService,
  ) {}

  get isConfigured(): boolean {
    return this.gemini.isConfigured;
  }

  async translate(text: string, targetLanguageCode: string): Promise<string> {
    const languageName = SUPPORTED_LANGUAGES[targetLanguageCode] ?? targetLanguageCode;
    const prompt =
      `Translate the following text into ${languageName}. ` +
      `Keep the tone and meaning exact, don't add commentary, output only the translation:\n\n${text}`;
    return this.gemini.generateText(prompt);
  }

  /** Last 7 days of notices/events/posts for a society, as context for the
   * community assistant and the digest - small enough to fit in one prompt
   * without needing a vector store for this scale of community. */
  private async recentContext(societyId: string) {
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const [notices, events, posts] = await Promise.all([
      this.prisma.notice.findMany({
        where: { societyId, createdAt: { gte: since } },
        orderBy: { createdAt: 'desc' },
        take: 30,
      }),
      this.prisma.event.findMany({
        where: { societyId, createdAt: { gte: since } },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
      this.prisma.post.findMany({
        where: { societyId, createdAt: { gte: since } },
        orderBy: { createdAt: 'desc' },
        take: 20,
      }),
    ]);

    const lines: string[] = [];
    for (const n of notices) lines.push(`[Notice] ${n.title}: ${n.body}`);
    for (const e of events) lines.push(`[Event] ${e.title} at ${e.location}: ${e.description}`);
    for (const p of posts) lines.push(`[Post] ${p.title ?? ''}: ${p.body}`);
    return lines.join('\n');
  }

  async answerCommunityQuestion(societyId: string, question: string): Promise<string> {
    const context = await this.recentContext(societyId);
    if (!context) {
      return "There's no recent community activity to answer that from yet.";
    }
    const prompt =
      'Answer the question using ONLY the community activity below. ' +
      "If the answer isn't in there, say you don't have that information - don't guess.\n\n" +
      `Community activity (last 7 days):\n${context}\n\nQuestion: ${question}`;
    return this.gemini.generateText(prompt);
  }

  /**
   * Best-effort "does this text look AI-generated" check - an experimental
   * heuristic (LLMs are notoriously unreliable at detecting their own or
   * other models' output; there's no solved, trustworthy version of this
   * problem today), never a verified fact. Must never be used to auto-hide
   * content or penalize a user - only ever shown as an informational badge
   * the viewer can take or leave. Returns null (not a guess) if Gemini's
   * response can't be parsed as a clean number, rather than risk a
   * nonsensical confidence value.
   */
  async detectAiGenerated(text: string): Promise<{ likely: boolean; confidence: number } | null> {
    const prompt =
      'On a scale of 0 to 100, how likely is it that the following text was ' +
      'written by an AI language model rather than a human? Respond with ' +
      'ONLY the number, nothing else.\n\n' +
      text.slice(0, 2000);
    const raw = await this.gemini.generateText(prompt);
    const confidence = parseInt(raw.replace(/[^0-9]/g, ''), 10);
    if (Number.isNaN(confidence) || confidence < 0 || confidence > 100) return null;
    return { likely: confidence >= 70, confidence };
  }

  async communitySummary(societyId: string): Promise<string> {
    const context = await this.recentContext(societyId);
    if (!context) {
      return 'No community activity in the last 7 days to summarize.';
    }
    const prompt =
      "Summarize this community's recent activity in a short, friendly digest. " +
      'Highlight what\'s trending and anything time-sensitive (events, deadlines). ' +
      `Keep it under 150 words.\n\n${context}`;
    return this.gemini.generateText(prompt);
  }
}
