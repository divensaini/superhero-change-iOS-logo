//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct TimelinePollView: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: TimelinePollViewModel.Context
    
    var body: some View {
        Group {
            switch viewModel.viewState.pollState {
            case .loading:
                TimelinePollMessageView(message: VectorL10n.pollTimelineLoading)
            case .loaded(let poll):
                pollContent(poll)
            case .errored:
                TimelinePollMessageView(message: VectorL10n.pollTimelineReplyEndedPoll)
            }
        }
        .alert(item: $viewModel.alertInfo) { info in
            info.alert
        }
    }
    
    @ViewBuilder
    private func pollContent(_ poll: TimelinePollDetails) -> some View {
        VStack(alignment: .leading, spacing: 16.0) {
            if poll.representsPollEndedEvent {
                Text(VectorL10n.pollTimelineEndedText)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.tertiaryContent)
            }
            
            Text(poll.question)
                .font(theme.fonts.bodySB)
                .foregroundColor(theme.colors.primaryContent) +
                Text(editedText(poll))
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryContent)
            
            VStack(spacing: 24.0) {
                ForEach(poll.answerOptions) { answerOption in
                    TimelinePollAnswerOptionButton(poll: poll, answerOption: answerOption) {
                        viewModel.send(viewAction: .selectAnswerOptionWithIdentifier(answerOption.id))
                    }
                }
            }
            .disabled(poll.closed)
            .fixedSize(horizontal: false, vertical: true)
            
            Text(totalVotesString(poll))
                .lineLimit(2)
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.tertiaryContent)
        }
        .padding([.horizontal, .top], 2.0)
        .padding([.bottom])
    }
    
    private func totalVotesString(_ poll: TimelinePollDetails) -> String {
        if poll.hasDecryptionError, poll.totalAnswerCount > 0 {
            return VectorL10n.pollTimelineDecryptionError
        }
        
        if poll.closed {
            if poll.totalAnswerCount == 1 {
                return VectorL10n.pollTimelineTotalFinalResultsOneVote
            } else {
                return VectorL10n.pollTimelineTotalFinalResults(Int(poll.totalAnswerCount))
            }
        }
        
        switch poll.totalAnswerCount {
        case 0:
            return VectorL10n.pollTimelineTotalNoVotes
        case 1:
            return (poll.hasCurrentUserVoted || poll.type == .undisclosed ?
                VectorL10n.pollTimelineTotalOneVote :
                VectorL10n.pollTimelineTotalOneVoteNotVoted)
        default:
            return (poll.hasCurrentUserVoted || poll.type == .undisclosed ?
                VectorL10n.pollTimelineTotalVotes(Int(poll.totalAnswerCount)) :
                VectorL10n.pollTimelineTotalVotesNotVoted(Int(poll.totalAnswerCount)))
        }
    }
    
    private func editedText(_ poll: TimelinePollDetails) -> String {
        poll.hasBeenEdited ? " \(VectorL10n.eventFormatterMessageEditedMention)" : ""
    }
}

// MARK: - Previews

struct TimelinePollView_Previews: PreviewProvider {
    static let stateRenderer = MockTimelinePollScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
