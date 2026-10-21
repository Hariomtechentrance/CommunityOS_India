import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * Thin wrapper over Gemini's REST API - no SDK needed, same "just fetch"
 * approach as RazorpayService. Picked over Claude/OpenAI specifically for
 * Indic-language quality (translation is the #1 requested feature) and
 * cost (Gemini Flash has a genuinely usable free tier for a bootstrapping
 * app) - see the conversation that led here for the full reasoning.
 */
@Injectable()
export class GeminiService {
  private readonly logger = new Logger(GeminiService.name);
  private readonly apiKey?: string;
  // "-latest" alias so this keeps working as Google retires/renames the
  // underlying model (gemini-2.0-flash, our original pick, was retired).
  private readonly model = 'gemini-flash-latest';

  constructor(config: ConfigService) {
    this.apiKey = config.get<string>('GEMINI_API_KEY');
  }

  get isConfigured(): boolean {
    return !!this.apiKey;
  }

  async generateText(prompt: string): Promise<string> {
    if (!this.apiKey) {
      throw new ServiceUnavailableException(
        'AI features are not configured yet (GEMINI_API_KEY missing)',
      );
    }

    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent?key=${this.apiKey}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
        }),
      },
    );

    if (!res.ok) {
      const body = await res.text();
      this.logger.error(`Gemini request failed: ${res.status} ${body}`);
      throw new ServiceUnavailableException('AI request failed');
    }

    const data = (await res.json()) as {
      candidates?: { content?: { parts?: { text?: string }[] } }[];
    };
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      this.logger.error(`Gemini returned no text: ${JSON.stringify(data)}`);
      throw new ServiceUnavailableException('AI returned an empty response');
    }
    return text.trim();
  }
}
